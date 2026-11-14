use std::sync::Arc;

use application::testing::FakeClock;
use infrastructure::http::ResponseCache;

use super::browse;
use super::service_support::{Folder, state};

#[tokio::test]
async fn clearing_without_a_cache_does_nothing() {
    let folder = Folder::new();
    let state = state(&folder).await;
    assert!(state.response_cache.is_none());
    browse::clear_catalog_cache(&state).await;
}

#[tokio::test]
async fn clearing_forgets_what_the_cache_held() {
    let folder = Folder::new();
    let cache = Arc::new(ResponseCache::new(
        folder.0.join("cache"),
        Arc::new(FakeClock::at(5)),
        10,
    ));
    cache.store("page", "body").await;
    let state = state(&folder).await.with_response_cache(cache.clone());
    assert!(cache.lookup("page").await.is_some());
    browse::clear_catalog_cache(&state).await;
    assert!(cache.lookup("page").await.is_none());
}
