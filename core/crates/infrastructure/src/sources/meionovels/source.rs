use std::sync::Arc;

use application::ports::{BoxFuture, Clock, SourceProvider, TextSource};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ChapterText, ItemId, SourceDetail, SourceId, SourceInfo, SourcePage,
    SourceSearch, StreamSupport, Unit,
};

use super::chapter_text::parse_chapter_text;
use super::chapters::parse_chapter_list;
use super::detail::parse_detail;
use super::listing::parse_listing_page;
use super::urls::MeionovelsUrls;
use crate::http::HttpClient;
use crate::sources::support::PageFetcher;

pub const MEIONOVELS_ID: &str = "meionovels";

pub struct MeionovelsSource {
    info: SourceInfo,
    urls: MeionovelsUrls,
    pages: PageFetcher,
}

impl MeionovelsSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        site_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(MEIONOVELS_ID),
                name: "Meionovels".into(),
                kind: MediaKind::Novel,
                priority,
                capabilities: Capabilities {
                    search: true,
                    latest: true,
                    genres: false,
                    stream: StreamSupport::None,
                },
                summary: "Light novel berbahasa Indonesia; sebagian terjemahannya hasil mesin."
                    .into(),
            },
            urls: MeionovelsUrls::new(site_url)?,
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

impl SourceProvider for MeionovelsSource {
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
            let html = self.pages.post_form(&url, &[]).await?;
            let chapters = parse_chapter_list(&html, item.as_str());
            if chapters.is_empty() {
                return Err(SourceError::MarkupChanged(
                    "chapter list was not found".into(),
                ));
            }
            Ok(chapters)
        })
    }

    fn texts(&self) -> Option<&dyn TextSource> {
        Some(self)
    }
}

impl TextSource for MeionovelsSource {
    fn chapter_text(&self, chapter: String) -> BoxFuture<'_, Result<ChapterText, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.chapter(&chapter)?).await?;
            parse_chapter_text(&html, self.urls.base())
        })
    }
}
