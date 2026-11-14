use std::sync::Arc;

use application::ports::{BoxFuture, Clock, SourceProvider};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, ItemId, SourceDetail, SourceId, SourceInfo, SourcePage, SourceSearch,
    StreamSupport, Unit,
};
use url::Url;

use super::parse::{parse_episodes, parse_items, parse_title};
use crate::http::HttpClient;
use crate::sources::support::{PageFetcher, is_slug};

pub const EXAMPLE_ID: &str = "example";

pub struct ExampleSource {
    info: SourceInfo,
    base: Url,
    pages: PageFetcher,
}

impl ExampleSource {
    pub fn new(
        http: Arc<dyn HttpClient>,
        clock: Arc<dyn Clock>,
        base_url: &str,
        priority: u8,
    ) -> Result<Self, SourceError> {
        let base = Url::parse(base_url)
            .map_err(|_| SourceError::Unsupported(format!("invalid source address: {base_url}")))?;
        Ok(Self {
            info: SourceInfo {
                id: SourceId::new(EXAMPLE_ID),
                name: "Example".into(),
                kind: MediaKind::Anime,
                priority,
                capabilities: Capabilities::full(StreamSupport::None),
                summary: String::new(),
            },
            base,
            pages: PageFetcher::new(http, clock),
        })
    }

    fn address(&self, path: &str) -> String {
        self.base.join(path).map(String::from).unwrap_or_default()
    }

    async fn title_page(&self, item: &ItemId) -> Result<String, SourceError> {
        if !is_slug(item.as_str(), &[]) {
            return Err(SourceError::NotFound(item.to_string()));
        }
        self.pages.fetch(&self.address(&format!("/title/{item}"))).await
    }

    async fn listing(&self, path: String) -> Result<SourcePage, SourceError> {
        let html = self.pages.fetch(&self.address(&path)).await?;
        Ok(SourcePage::single(parse_items(&html)?))
    }
}

impl SourceProvider for ExampleSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, _page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move { self.listing("/latest".into()).await })
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move { self.listing(format!("/search?q={}", search.query)).await })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            let title = parse_title(&self.title_page(&item).await?)?;
            Ok(SourceDetail::new(domain::source::SourceItem::new(item, title)))
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move { parse_episodes(&self.title_page(&item).await?) })
    }
}
