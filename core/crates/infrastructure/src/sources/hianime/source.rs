use std::sync::Arc;

use application::ports::{BoxFuture, Clock, SourceProvider, VideoSource};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ItemId, SourceDetail, SourceId, SourceInfo, SourcePage, SourceSearch,
    StreamSupport, Unit,
};

use super::api::parse_json;
use super::episodes::units_of;
use super::items::{detail_of, items_of};
use super::model::{RawDetail, RawEpisodes, RawFilter, RawLatest, RawAnime, number_of};
use super::query::{filter_body, query_variants};
use super::urls::HianimeUrls;
use super::video::HianimeVideo;
use crate::http::HttpClient;
use crate::sources::support::PageFetcher;

pub const HIANIME_ID: &str = "hianime";
const SUMMARY: &str = "Kebanyakan subtitle Inggris, sebagian punya Indonesia dan bahasa lain. Ada pilihan resolusi sampai 1080p, sulih suara, dan tombol lewati intro.";
const WINDOW: u32 = 100;
const MAX_WINDOWS: u32 = 30;

pub struct HianimeSource {
    info: SourceInfo,
    urls: HianimeUrls,
    pages: Arc<PageFetcher>,
    video: HianimeVideo,
}

impl HianimeSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        api_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        let urls = HianimeUrls::new(api_url)?;
        let pages = Arc::new(PageFetcher::new(http, clock));
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(HIANIME_ID),
                name: "Hianime".into(),
                kind: MediaKind::Anime,
                priority,
                capabilities: Capabilities {
                    search: true,
                    latest: true,
                    genres: false,
                    stream: StreamSupport::NeedsWebView,
                },
                summary: SUMMARY.into(),
            },
            video: HianimeVideo::new(urls.clone(), Arc::clone(&pages)),
            urls,
            pages,
        })
    }

    async fn filter_page(&self, keyword: &str, page: u32) -> Result<SourcePage, SourceError> {
        let body = self
            .pages
            .post_json(&self.urls.filter(), &filter_body(keyword, page))
            .await?;
        let filter: RawFilter = parse_json(&body, "search")?;
        Ok(SourcePage {
            items: items_of(filter.results),
            page: page.max(1),
            total_pages: filter.total_pages.unwrap_or(1).max(1),
        })
    }

    async fn searched(&self, search: &SourceSearch) -> Result<SourcePage, SourceError> {
        let page = search.page.max(1);
        let mut variants = query_variants(&search.query);
        if page > 1 {
            variants.truncate(1);
        }
        let mut last = SourcePage {
            items: Vec::new(),
            page,
            total_pages: 1,
        };
        for variant in variants {
            last = self.filter_page(&variant, page).await?;
            if !last.items.is_empty() {
                break;
            }
        }
        Ok(last)
    }

    async fn anime(&self, slug: &str) -> Result<RawAnime, SourceError> {
        let body = self.pages.fetch(&self.urls.anime(slug)?).await?;
        let detail: RawDetail = parse_json(&body, "title")?;
        Ok(detail.anime)
    }

    async fn all_units(&self, slug: &str) -> Result<Vec<Unit>, SourceError> {
        let anime = self.anime(slug).await?;
        let id = anime
            .id
            .clone()
            .ok_or_else(|| SourceError::MarkupChanged("the title has no id".into()))?;
        let expected = anime.total_episodes.as_ref().and_then(number_of).unwrap_or(0);
        let mut units: Vec<Unit> = Vec::new();
        let mut start = 1;
        for _ in 0..MAX_WINDOWS {
            let end = start + WINDOW - 1;
            let body = self.pages.fetch(&self.urls.episodes(&id, start, end)?).await?;
            let page: RawEpisodes = parse_json(&body, "episodes")?;
            let listed = page.episodes.ok_or_else(|| {
                SourceError::MarkupChanged("episode list was not found".into())
            })?;
            let empty = listed.is_empty();
            units.extend(units_of(listed));
            let total = page.total.unwrap_or(expected).max(expected);
            if empty || end >= total {
                break;
            }
            start = end + 1;
        }
        units.sort_by(|a, b| a.number.total_cmp(&b.number));
        units.dedup_by(|later, earlier| later.id == earlier.id);
        Ok(units)
    }
}

impl SourceProvider for HianimeSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            let body = self.pages.fetch(&self.urls.latest(page)).await?;
            let latest: RawLatest = parse_json(&body, "latest")?;
            Ok(SourcePage {
                items: items_of(latest.animes),
                page: page.max(1),
                total_pages: latest.total_pages.unwrap_or(1).max(1),
            })
        })
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move { self.searched(&search).await })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            let anime = self.anime(item.as_str()).await?;
            detail_of(&anime).ok_or_else(|| SourceError::NotFound(item.to_string()))
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move { self.all_units(item.as_str()).await })
    }

    fn video(&self) -> Option<&dyn VideoSource> {
        Some(&self.video)
    }
}
