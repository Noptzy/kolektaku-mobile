use std::sync::Arc;

use application::ports::{BoxFuture, Clock, SourceProvider, TextSource};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ChapterText, ItemId, SourceDetail, SourceId, SourceInfo, SourcePage,
    SourceSearch, StreamSupport, Unit,
};

use super::catalog::{first_titles, matching_titles, parse_categories};
use super::chapter_text::parse_chapter_text;
use super::detail::{parse_detail, parse_units};
use super::urls::BakaTsukiUrls;
use crate::http::HttpClient;
use crate::sources::support::PageFetcher;

pub const BAKATSUKI_ID: &str = "bakatsuki";
const LISTING_PAGE: usize = 40;

pub struct BakaTsukiSource {
    info: SourceInfo,
    urls: BakaTsukiUrls,
    pages: PageFetcher,
}

impl BakaTsukiSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        site_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(BAKATSUKI_ID),
                name: "Baka-Tsuki".into(),
                kind: MediaKind::Novel,
                priority,
                capabilities: Capabilities {
                    search: true,
                    latest: true,
                    genres: false,
                    stream: StreamSupport::None,
                },
                summary: "Sumber cadangan: light novel berbahasa Inggris terjemahan penggemar, hanya sebagian judul."
                    .into(),
            },
            urls: BakaTsukiUrls::new(site_url)?,
            pages: PageFetcher::new(http, clock),
        })
    }

    async fn titles(&self) -> Result<Vec<String>, SourceError> {
        let json = self.pages.fetch(&self.urls.categories()).await?;
        parse_categories(&json)
    }
}

impl SourceProvider for BakaTsukiSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            let titles = self.titles().await?;
            let total = titles.len().div_ceil(LISTING_PAGE).max(1) as u32;
            Ok(SourcePage {
                items: first_titles(&titles, LISTING_PAGE, page),
                page: page.max(1),
                total_pages: total,
            })
        })
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
            let titles = self.titles().await?;
            Ok(SourcePage::single(matching_titles(&titles, &search.query)))
        })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.page(item.as_str())?).await?;
            parse_detail(&html, item.as_str(), self.urls.base())
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.page(item.as_str())?).await?;
            let units = parse_units(&html, item.as_str(), self.urls.base());
            if units.is_empty() {
                return Err(SourceError::MarkupChanged(
                    "chapter list was not found".into(),
                ));
            }
            Ok(units)
        })
    }

    fn texts(&self) -> Option<&dyn TextSource> {
        Some(self)
    }
}

impl TextSource for BakaTsukiSource {
    fn chapter_text(&self, chapter: String) -> BoxFuture<'_, Result<ChapterText, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.page(&chapter)?).await?;
            parse_chapter_text(&html, self.urls.base())
        })
    }
}
