use application::testing::FakeClock;

use super::*;
use crate::http::FakeHttp;
use crate::storage::Database;

fn rig(
    replies: Vec<Result<HttpResponse, SourceError>>,
) -> (PageFetcher, Arc<FakeHttp>, Arc<FakeClock>) {
    let http = Arc::new(FakeHttp::scripted(replies));
    let clock = Arc::new(FakeClock::at(1_000));
    let cache = Arc::new(ResponseCache::in_database(
        Database::in_memory().unwrap(),
        "pages",
        clock.clone(),
        10,
    ));
    let fetcher = PageFetcher::new(http.clone(), clock.clone()).with_saved_pages(cache);
    (fetcher, http, clock)
}

fn page(body: &str) -> Result<HttpResponse, SourceError> {
    Ok(HttpResponse::new(200, body))
}

#[tokio::test]
async fn a_page_survives_the_short_memory_cache_for_fifteen_minutes() {
    let (fetcher, http, clock) = rig(vec![page("one"), page("two")]);
    assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "one");
    clock.advance(600);
    assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "one");
    assert_eq!(http.requests().len(), 1);
    clock.advance(400);
    assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "two");
    assert_eq!(http.requests().len(), 2);
}

#[tokio::test]
async fn an_old_page_is_served_when_the_site_is_down() {
    let down = Err(SourceError::Network("offline".into()));
    let (fetcher, _http, clock) = rig(vec![page("old"), down]);
    fetcher.fetch("https://s.test/a").await.unwrap();
    clock.advance(5_000);
    assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "old");
}

#[tokio::test]
async fn a_failed_page_is_never_saved_and_live_fetches_skip_the_saved_copy() {
    let (fetcher, http, clock) = rig(vec![
        Ok(HttpResponse::new(404, "")),
        page("fresh"),
        page("fresher"),
    ]);
    assert!(fetcher.fetch("https://s.test/a").await.is_err());
    assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "fresh");
    clock.advance(200);
    assert_eq!(
        fetcher.fetch_live("https://s.test/a").await.unwrap(),
        "fresher"
    );
    assert_eq!(http.requests().len(), 3);
}
