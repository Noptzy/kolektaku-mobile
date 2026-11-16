use std::sync::Arc;
use std::time::Duration;

use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceDetail, SourceInfo, SourcePage, SourceSearch, Unit};

use super::SearchMedia;
use super::search_test_support::{anime, item, source};
use crate::ports::{BoxFuture, SourceProvider};
use crate::testing::{FakeCatalog, FakeClock, FakeSource};

struct SlowSource {
    inner: FakeSource,
    delay: Duration,
}

impl SourceProvider for SlowSource {
    fn info(&self) -> &SourceInfo {
        self.inner.info()
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        self.inner.latest(page)
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            tokio::time::sleep(self.delay).await;
            self.inner.search(search).await
        })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        self.inner.detail(item)
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        self.inner.units(item)
    }
}

fn use_case(slow: Duration) -> SearchMedia<FakeCatalog> {
    let catalog =
        FakeCatalog::new().with_search(MediaKind::Anime, "naruto", vec![anime(20, "Naruto", &[])]);
    let providers: Vec<Arc<dyn SourceProvider>> = vec![
        Arc::new(SlowSource {
            inner: source("slow").with_search("naruto", vec![item("s/naruto", "Naruto")]),
            delay: slow,
        }),
        Arc::new(source("fast").with_search("naruto", vec![item("f/naruto", "Naruto")])),
    ];
    SearchMedia::new(Arc::new(catalog), providers, Arc::new(FakeClock::at(1_000)))
}

#[tokio::test(start_paused = true)]
async fn a_site_that_takes_too_long_is_left_out_with_a_notice() {
    let outcome = use_case(Duration::from_secs(60))
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    assert_eq!(outcome.cards[0].links.len(), 1);
    assert_eq!(outcome.cards[0].links[0].source.as_str(), "fast");
    assert_eq!(outcome.notices.len(), 1);
    assert_eq!(
        outcome.notices[0].origin.as_ref().map(|id| id.as_str()),
        Some("slow")
    );
}

#[tokio::test(start_paused = true)]
async fn a_site_that_answers_within_the_limit_is_kept() {
    let outcome = use_case(Duration::from_secs(3))
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards[0].links.len(), 2);
    assert!(outcome.notices.is_empty());
}
