use domain::error::SourceError;
use domain::source::{
    Genre, ItemId, SourceDetail, SourceInfo, SourceOrder, SourcePage, SourceSearch, Unit,
};

use super::{BoxFuture, PageSource, TextSource, VideoSource};

pub trait SourceProvider: Send + Sync {
    fn info(&self) -> &SourceInfo;

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>>;

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>>;

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>>;

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>>;

    fn genres(&self) -> BoxFuture<'_, Result<Vec<Genre>, SourceError>> {
        Box::pin(async { Err(SourceError::Unsupported("genres".into())) })
    }

    fn by_genre(
        &self,
        _slug: String,
        _page: u32,
        _order: SourceOrder,
    ) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async { Err(SourceError::Unsupported("genre listing".into())) })
    }

    fn video(&self) -> Option<&dyn VideoSource> {
        None
    }

    fn pages(&self) -> Option<&dyn PageSource> {
        None
    }

    fn texts(&self) -> Option<&dyn TextSource> {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use domain::media::MediaKind;
    use domain::source::{Capabilities, SourceId, StreamSupport};

    struct MinimalSource {
        info: SourceInfo,
    }

    impl MinimalSource {
        fn new() -> Self {
            let info = SourceInfo {
                id: SourceId::new("minimal"),
                name: "Minimal".into(),
                kind: MediaKind::Anime,
                priority: 1,
                capabilities: Capabilities::full(StreamSupport::None),
                summary: String::new(),
            };
            Self { info }
        }
    }

    impl SourceProvider for MinimalSource {
        fn info(&self) -> &SourceInfo {
            &self.info
        }

        fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
            Box::pin(async move {
                Ok(SourcePage {
                    items: Vec::new(),
                    page,
                    total_pages: 1,
                })
            })
        }

        fn search(&self, _search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
            Box::pin(async { Ok(SourcePage::single(Vec::new())) })
        }

        fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
            Box::pin(async move { Err(SourceError::NotFound(item.to_string())) })
        }

        fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
            Box::pin(async move { Err(SourceError::NotFound(item.to_string())) })
        }
    }

    #[tokio::test]
    async fn genres_are_unsupported_unless_the_source_overrides_them() {
        let source = MinimalSource::new();
        assert!(matches!(
            source.genres().await,
            Err(SourceError::Unsupported(_))
        ));
    }

    #[tokio::test]
    async fn genre_listing_is_unsupported_by_default() {
        let source = MinimalSource::new();
        let result = source
            .by_genre("action".into(), 1, SourceOrder::Newest)
            .await;
        assert!(matches!(result, Err(SourceError::Unsupported(_))));
    }

    #[test]
    fn video_and_page_capabilities_are_absent_by_default() {
        let source = MinimalSource::new();
        assert!(source.video().is_none());
        assert!(source.pages().is_none());
    }

    #[test]
    fn the_trait_is_object_safe() {
        let boxed: Box<dyn SourceProvider> = Box::new(MinimalSource::new());
        assert_eq!(boxed.info().id.as_str(), "minimal");
    }
}
