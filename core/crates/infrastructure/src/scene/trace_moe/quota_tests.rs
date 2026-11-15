use std::sync::Arc;

use application::ports::SceneSearch;
use domain::error::SourceError;

use super::TraceMoeSceneSearch;
use crate::fixtures;
use crate::http::{FakeHttp, FakePause, HttpMethod, HttpResponse};

fn search_with(http: Arc<FakeHttp>) -> TraceMoeSceneSearch {
    TraceMoeSceneSearch::new(http, Arc::new(FakePause::at(0)))
}

#[tokio::test]
async fn the_recorded_reply_gives_the_remaining_quota() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        fixtures::trace_moe("me_sample.json"),
    )));
    assert_eq!(search_with(http).quota_left().await, Ok(100));
}

#[tokio::test]
async fn used_requests_are_subtracted() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        r#"{"id":"x","priority":0,"concurrency":1,"quota":100,"quotaUsed":37}"#,
    )));
    assert_eq!(search_with(http).quota_left().await, Ok(63));
}

#[tokio::test]
async fn the_quota_is_asked_with_a_plain_get_and_no_image() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        r#"{"quota":10,"quotaUsed":1}"#,
    )));
    search_with(http.clone()).quota_left().await.unwrap();
    let request = &http.requests()[0];
    assert_eq!(request.method, HttpMethod::Get);
    assert_eq!(request.url, "https://api.trace.moe/me");
    assert_eq!(request.bytes, None);
}

#[tokio::test]
async fn a_reply_without_the_numbers_means_the_markup_changed() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, r#"{"id":"x"}"#)));
    assert!(matches!(
        search_with(http).quota_left().await,
        Err(SourceError::MarkupChanged(_))
    ));
}

#[tokio::test]
async fn a_body_that_is_not_json_means_the_markup_changed() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "<html>")));
    assert!(matches!(
        search_with(http).quota_left().await,
        Err(SourceError::MarkupChanged(_))
    ));
}

#[tokio::test]
async fn a_busy_service_is_reported_not_retried() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(429, "")));
    let result = search_with(http.clone()).quota_left().await;
    assert!(matches!(result, Err(SourceError::RateLimited { .. })));
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn any_other_status_is_unavailable() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(500, "")));
    assert_eq!(
        search_with(http).quota_left().await,
        Err(SourceError::Unavailable("http 500".into()))
    );
}
