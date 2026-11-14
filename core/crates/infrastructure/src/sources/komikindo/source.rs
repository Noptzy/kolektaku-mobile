use std::sync::Arc;

use application::ports::{BoxFuture, Clock, PageSource, SourceProvider};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ChapterPages, Genre, ItemId, SourceDetail, SourceId, SourceInfo, SourceOrder,
    SourcePage, SourceSearch, StreamSupport, Unit,
};

use super::chapter::parse_chapter_pages;
use super::detail::{parse_chapter_list, parse_detail};
use super::genres::parse_genres;
use super::listing::parse_listing_page;
use super::urls::KomikindoUrls;
use crate::http::HttpClient;
use crate::sources::support::PageFetcher;

pub const KOMIKINDO_ID: &str = "komikindo";

pub struct KomikindoSource {
    info: SourceInfo,
    urls: KomikindoUrls,
    pages: PageFetcher,
}

impl KomikindoSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        base_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(KOMIKINDO_ID),
                name: "KomikIndo".into(),
                kind: MediaKind::Manga,
                priority,
                capabilities: Capabilities::full(StreamSupport::None),
                summary: "Manga berbahasa Indonesia.".into(),
            },
            urls: KomikindoUrls::new(base_url)?,
            pages: PageFetcher::new(http, clock),
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

    async fn detail_html(&self, item: &str) -> Result<String, SourceError> {
        self.pages.fetch(&self.urls.detail(item)?).await
    }
}

impl SourceProvider for KomikindoSource {
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
            let html = self.detail_html(item.as_str()).await?;
            parse_detail(&html, item.as_str(), self.urls.base())
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move {
            let chapters = parse_chapter_list(&self.detail_html(item.as_str()).await?);
            if chapters.is_empty() {
                return Err(SourceError::MarkupChanged(
                    "chapter list was not found".into(),
                ));
            }
            Ok(chapters)
        })
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

    fn pages(&self) -> Option<&dyn PageSource> {
        Some(self)
    }
}

impl PageSource for KomikindoSource {
    fn chapter_pages(&self, chapter: String) -> BoxFuture<'_, Result<ChapterPages, SourceError>> {
        Box::pin(async move {
            let html = self.pages.fetch(&self.urls.chapter(&chapter)?).await?;
            parse_chapter_pages(&html, self.urls.base())
        })
    }
}
