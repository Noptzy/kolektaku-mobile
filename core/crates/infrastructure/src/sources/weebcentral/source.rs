use std::sync::Arc;

use application::ports::{BoxFuture, Clock, PageSource, SourceProvider};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ChapterPages, ItemId, SourceDetail, SourceId, SourceInfo, SourcePage,
    SourceSearch, StreamSupport, Unit,
};

use super::chapter_pages::parse_chapter_pages;
use super::chapters::parse_chapter_list;
use super::detail::parse_detail;
use super::listing::parse_listing_page;
use super::urls::WeebCentralUrls;
use crate::http::HttpClient;
use crate::sources::support::PageFetcher;

pub const WEEBCENTRAL_ID: &str = "weebcentral";

pub struct WeebCentralSource {
    info: SourceInfo,
    urls: WeebCentralUrls,
    pages: PageFetcher,
}

impl WeebCentralSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        site_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(WEEBCENTRAL_ID),
                name: "Weeb Central".into(),
                kind: MediaKind::Manga,
                priority,
                capabilities: Capabilities {
                    search: true,
                    latest: true,
                    genres: false,
                    stream: StreamSupport::None,
                },
                summary: "Bahasa Inggris".into(),
            },
            urls: WeebCentralUrls::new(site_url)?,
            pages: PageFetcher::new(http, clock),
        })
    }

    async fn listing(&self, url: String, page: u32) -> Result<SourcePage, SourceError> {
        let html = self.pages.fetch(&url).await?;
        let parsed = parse_listing_page(&html, self.urls.base())?;
        let total_pages = if parsed.has_next_page { page + 1 } else { page };
        Ok(SourcePage {
            items: parsed.items,
            page,
            total_pages,
        })
    }
}

impl SourceProvider for WeebCentralSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move { self.listing(self.urls.latest(page), page).await })
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            if search.page > 1 {
                return Ok(SourcePage {
                    items: Vec::new(),
                    page: search.page,
                    total_pages: 1,
                });
            }
            self.listing(self.urls.search(&search.query), 1).await
        })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            let url = self.urls.detail(item.as_str())?;
            let html = self.pages.fetch(&url).await?;
            parse_detail(&html, item.as_str(), self.urls.base())
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move {
            let url = self.urls.chapter_list(item.as_str())?;
            let chapters = parse_chapter_list(&self.pages.fetch(&url).await?);
            if chapters.is_empty() {
                return Err(SourceError::MarkupChanged(
                    "chapter list was not found".into(),
                ));
            }
            Ok(chapters)
        })
    }

    fn pages(&self) -> Option<&dyn PageSource> {
        Some(self)
    }
}

impl PageSource for WeebCentralSource {
    fn chapter_pages(&self, chapter: String) -> BoxFuture<'_, Result<ChapterPages, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.images(&chapter)?).await?;
            parse_chapter_pages(&html, self.urls.base())
        })
    }
}
