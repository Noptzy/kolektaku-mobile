use std::sync::Arc;

use domain::error::SourceError;

use super::{
    FakeHttp, FakePause, HttpClient, HttpRequest, HttpResponse, RateLimitSettings,
    RateLimitedClient,
};

const START: u64 = 1_000_000;

type Reply = Result<HttpResponse, SourceError>;

fn limited(replies: Vec<Reply>) -> (RateLimitedClient, Arc<FakeHttp>, Arc<FakePause>) {
    let inner = Arc::new(FakeHttp::scripted(replies));
    let pause = Arc::new(FakePause::at(START));
    let client = RateLimitedClient::new(inner.clone(), pause.clone(), RateLimitSettings::default());
    (client, inner, pause)
}

fn ok(status: u16) -> Reply {
    Ok(HttpResponse::new(status, "{}"))
}

#[tokio::test]
async fn requests_pass_straight_through_while_plenty_of_quota_remains() {
    let first = HttpResponse::new(200, "{}").with_header("x-ratelimit-remaining", "80");
    let (client, inner, pause) = limited(vec![Ok(first), ok(200)]);
    client
        .send(HttpRequest::get("https://x.test/1"))
        .await
        .unwrap();
    client
        .send(HttpRequest::get("https://x.test/2"))
        .await
        .unwrap();
    assert!(pause.sleeps().is_empty());
    assert_eq!(inner.requests().len(), 2);
}

#[tokio::test]
async fn the_next_request_waits_for_the_window_when_fewer_than_five_remain() {
    let reset = (START / 1000 + 20).to_string();
    let first = HttpResponse::new(200, "{}")
        .with_header("x-ratelimit-remaining", "3")
        .with_header("x-ratelimit-reset", &reset);
    let (client, _, pause) = limited(vec![Ok(first), ok(200)]);
    client
        .send(HttpRequest::get("https://x.test/1"))
        .await
        .unwrap();
    client
        .send(HttpRequest::get("https://x.test/2"))
        .await
        .unwrap();
    assert_eq!(pause.sleeps(), vec![20_000]);
}

#[tokio::test]
async fn a_low_quota_without_a_reset_header_waits_ten_seconds() {
    let first = HttpResponse::new(200, "{}").with_header("x-ratelimit-remaining", "0");
    let (client, _, pause) = limited(vec![Ok(first), ok(200)]);
    client
        .send(HttpRequest::get("https://x.test/1"))
        .await
        .unwrap();
    client
        .send(HttpRequest::get("https://x.test/2"))
        .await
        .unwrap();
    assert_eq!(pause.sleeps(), vec![10_000]);
}

#[tokio::test]
async fn a_429_waits_for_retry_after_and_retries_once() {
    let throttled = HttpResponse::new(429, "{}").with_header("retry-after", "7");
    let (client, inner, pause) = limited(vec![Ok(throttled), ok(200)]);
    let response = client
        .send(HttpRequest::get("https://x.test/"))
        .await
        .unwrap();
    assert_eq!(response.status, 200);
    assert_eq!(pause.sleeps(), vec![7_000]);
    assert_eq!(inner.requests().len(), 2);
}

#[tokio::test]
async fn it_gives_up_after_the_retry_budget_and_returns_the_429() {
    let again = || Ok(HttpResponse::new(429, "{}").with_header("retry-after", "1"));
    let (client, inner, _) = limited(vec![again(), again()]);
    let response = client
        .send(HttpRequest::get("https://x.test/"))
        .await
        .unwrap();
    assert_eq!(response.status, 429);
    assert_eq!(inner.requests().len(), 2);
}

#[tokio::test]
async fn an_absurd_retry_after_is_capped() {
    let huge = HttpResponse::new(429, "{}").with_header("retry-after", "86400");
    let (client, _, pause) = limited(vec![Ok(huge), ok(200)]);
    client
        .send(HttpRequest::get("https://x.test/"))
        .await
        .unwrap();
    assert_eq!(pause.sleeps(), vec![65_000]);
}

#[tokio::test]
async fn transport_errors_are_passed_on_without_retrying() {
    let (client, inner, _) = limited(vec![Err(SourceError::Network("offline".into()))]);
    let error = client
        .send(HttpRequest::get("https://x.test/"))
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::Network("offline".into()));
    assert_eq!(inner.requests().len(), 1);
}
