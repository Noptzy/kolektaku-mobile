use std::sync::Arc;

use application::ports::{BoxFuture, Clock, SourceProvider, VideoSource};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ItemId, SourceDetail, SourceId, SourceInfo, SourcePage, SourceSearch,
    StreamSupport, Unit,
};

use super::detail::{looks_like_a_detail_page, parse_detail};
use super::episodes::parse_units;
use super::listing::parse_listing;
use super::urls::GogoanimeUrls;
use super::video::GogoanimeVideo;
use crate::http::HttpClient;
use crate::sources::support::PageFetcher;

pub const GOGOANIME_ID: &str = "gogoanime";

pub struct GogoanimeSource {
    info: SourceInfo,
    urls: GogoanimeUrls,
    pages: Arc<PageFetcher>,
    video: GogoanimeVideo,
}

impl GogoanimeSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        base_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        let urls = GogoanimeUrls::new(base_url)?;
        let pages = Arc::new(PageFetcher::new(http, clock));
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(GOGOANIME_ID),
                name: "Gogoanime".into(),
                kind: MediaKind::Anime,
                priority,
                capabilities: Capabilities {
                    search: true,
                    latest: true,
                    genres: false,
                    stream: StreamSupport::NeedsWebView,
                },
                summary: "Subtitle Inggris, dub tersedia di banyak judul.".into(),
            },
            video: GogoanimeVideo::new(urls.clone(), Arc::clone(&pages)),
            urls,
            pages,
        })
    }

    async fn listing(&self, url: String, page: u32) -> Result<SourcePage, SourceError> {
        let html = self.pages.fetch(&url).await?;
        let parsed = parse_listing(&html, &self.urls, page.max(1))?;
        Ok(SourcePage {
            items: parsed.items,
            page: page.max(1),
            total_pages: parsed.total_pages,
        })
    }
}

impl SourceProvider for GogoanimeSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move { self.listing(self.urls.latest(page), page).await })
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            let url = self.urls.search(&search.query, search.page);
            self.listing(url, search.page).await
        })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.anime(item.as_str())?).await?;
            parse_detail(&html, item.as_str(), &self.urls)
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.anime(item.as_str())?).await?;
            let units = parse_units(&html);
            if units.is_empty() && !looks_like_a_detail_page(&html) {
                return Err(SourceError::MarkupChanged(
                    "episode list was not found".into(),
                ));
            }
            Ok(units)
        })
    }

    fn video(&self) -> Option<&dyn VideoSource> {
        Some(&self.video)
    }
}
