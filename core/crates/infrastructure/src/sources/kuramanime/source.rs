use std::sync::Arc;

use application::ports::{BoxFuture, Clock, SourceProvider, VideoSource};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, Genre, ItemId, SourceDetail, SourceId, SourceInfo, SourceOrder, SourcePage,
    SourceSearch, StreamSupport, Unit,
};

use super::detail::{looks_like_a_detail_page, parse_detail};
use super::episodes::{merge_episodes, parse_episode_page};
use super::genres::parse_genres;
use super::listing::parse_listing_page;
use super::urls::KuramanimeUrls;
use super::video::KuramanimeVideo;
use crate::http::HttpClient;
use crate::sources::support::{PageFetcher, fetch_all};

pub const KURAMANIME_ID: &str = "kuramanime";
const EPISODE_PAGE_BATCH: u32 = 6;
const MAX_EPISODE_PAGES: u32 = 200;

pub struct KuramanimeSource {
    info: SourceInfo,
    urls: KuramanimeUrls,
    pages: Arc<PageFetcher>,
    video: KuramanimeVideo,
}

impl KuramanimeSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        base_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        let urls = KuramanimeUrls::new(base_url)?;
        let pages = Arc::new(PageFetcher::new(http, clock));
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(KURAMANIME_ID),
                name: "Kuramanime".into(),
                kind: MediaKind::Anime,
                priority,
                capabilities: Capabilities::full(StreamSupport::NeedsWebView),
                summary: "Subtitle Indonesia selalu tersedia.".into(),
            },
            video: KuramanimeVideo::new(urls.clone(), Arc::clone(&pages)),
            urls,
            pages,
        })
    }

    async fn listing(&self, url: String, page: u32) -> Result<SourcePage, SourceError> {
        let html = self.pages.fetch(&url).await?;
        let parsed = parse_listing_page(&html, self.urls.base())?;
        Ok(SourcePage {
            items: parsed.items,
            page,
            total_pages: parsed.total_pages,
        })
    }

    async fn all_units(&self, item: &str) -> Result<Vec<Unit>, SourceError> {
        let first_html = self.pages.fetch(&self.urls.detail(item, 1)?).await?;
        let first = parse_episode_page(&first_html);
        if first.episodes.is_empty() && !looks_like_a_detail_page(&first_html) {
            return Err(SourceError::MarkupChanged(
                "episode list was not found".into(),
            ));
        }
        if !first.has_next_page {
            return Ok(merge_episodes(first.episodes));
        }
        let mut episodes = first.episodes;
        episodes.extend(self.remaining_episodes(item).await?);
        Ok(merge_episodes(episodes))
    }

    async fn remaining_episodes(&self, item: &str) -> Result<Vec<Unit>, SourceError> {
        let mut episodes = Vec::new();
        let mut first = 2;
        while first <= MAX_EPISODE_PAGES {
            let urls = (first..first + EPISODE_PAGE_BATCH)
                .map(|page| self.urls.detail(item, page))
                .collect::<Result<Vec<_>, _>>()?;
            for body in fetch_all(&self.pages, urls).await {
                let page = parse_episode_page(&body?);
                episodes.extend(page.episodes);
                if !page.has_next_page {
                    return Ok(episodes);
                }
            }
            first += EPISODE_PAGE_BATCH;
        }
        Ok(episodes)
    }
}

impl SourceProvider for KuramanimeSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move { self.listing(self.urls.latest(page), page).await })
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            let url = self.urls.search(&search.query, search.page, search.order);
            self.listing(url, search.page).await
        })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            let html = self
                .pages
                .fetch(&self.urls.detail(item.as_str(), 1)?)
                .await?;
            parse_detail(&html, item.as_str(), self.urls.base())
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move { self.all_units(item.as_str()).await })
    }

    fn genres(&self) -> BoxFuture<'_, Result<Vec<Genre>, SourceError>> {
        Box::pin(async move { parse_genres(&self.pages.fetch(&self.urls.genres()).await?) })
    }

    fn by_genre(
        &self,
        slug: String,
        page: u32,
        order: SourceOrder,
    ) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            let url = self.urls.genre(&slug, page, order)?;
            self.listing(url, page).await
        })
    }

    fn video(&self) -> Option<&dyn VideoSource> {
        Some(&self.video)
    }
}
