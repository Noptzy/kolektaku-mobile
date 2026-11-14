use std::sync::Arc;

use application::ports::SceneSearch;
use domain::error::SourceError;

use super::TraceMoeSceneSearch;
use crate::http::{FakeHttp, FakePause, HttpResponse};

fn ok_reply() -> HttpResponse {
    HttpResponse::new(200, r#"{"error":"","quota":100,"quotaUsed":1,"result":[]}"#)
}

fn run(
    replies: Vec<Result<HttpResponse, SourceError>>,
) -> (TraceMoeSceneSearch, Arc<FakeHttp>, Arc<FakePause>) {
    let http = Arc::new(FakeHttp::scripted(replies));
    let pause = Arc::new(FakePause::at(0));
    (
        TraceMoeSceneSearch::new(http.clone(), pause.clone()),
        http,
        pause,
    )
}

#[tokio::test]
async fn a_402_is_the_daily_limit() {
    let (search, http, _) = run(vec![Ok(HttpResponse::new(402, "{}"))]);
    assert_eq!(search.find(vec![1]).await, Err(SourceError::QuotaExceeded));
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn a_quota_message_in_the_body_is_the_daily_limit() {
    let (search, _, _) = run(vec![Ok(HttpResponse::new(
        200,
        r#"{"error":"Search quota depleted","result":[]}"#,
    ))]);
    assert_eq!(search.find(vec![1]).await, Err(SourceError::QuotaExceeded));
}

#[tokio::test]
async fn another_error_message_is_the_service_being_unavailable() {
    let (search, _, _) = run(vec![Ok(HttpResponse::new(
        200,
        r#"{"error":"Failed to process image","result":[]}"#,
    ))]);
    assert_eq!(
        search.find(vec![1]).await,
        Err(SourceError::Unavailable("Failed to process image".into()))
    );
}

#[tokio::test]
async fn a_429_is_retried_after_a_pause_and_then_succeeds() {
    let (search, http, pause) = run(vec![Ok(HttpResponse::new(429, "")), Ok(ok_reply())]);
    assert!(search.find(vec![1]).await.is_ok());
    assert_eq!(http.requests().len(), 2);
    assert_eq!(pause.sleeps(), vec![2_000]);
}

#[tokio::test]
async fn two_retries_use_growing_pauses() {
    let (search, http, pause) = run(vec![
        Ok(HttpResponse::new(503, "")),
        Ok(HttpResponse::new(429, "")),
        Ok(ok_reply()),
    ]);
    assert!(search.find(vec![1]).await.is_ok());
    assert_eq!(http.requests().len(), 3);
    assert_eq!(pause.sleeps(), vec![2_000, 4_000]);
}

#[tokio::test]
async fn after_two_retries_it_gives_up_as_rate_limited() {
    let (search, http, _) = run(vec![
        Ok(HttpResponse::new(429, "")),
        Ok(HttpResponse::new(429, "")),
        Ok(HttpResponse::new(429, "").with_header("retry-after", "30")),
    ]);
    assert_eq!(
        search.find(vec![1]).await,
        Err(SourceError::RateLimited {
            retry_after_secs: Some(30)
        })
    );
    assert_eq!(http.requests().len(), 3);
}

#[tokio::test]
async fn retry_after_is_honoured_but_capped_at_ten_seconds() {
    let (search, _, pause) = run(vec![
        Ok(HttpResponse::new(429, "").with_header("retry-after", "3")),
        Ok(HttpResponse::new(429, "").with_header("retry-after", "600")),
        Ok(ok_reply()),
    ]);
    assert!(search.find(vec![1]).await.is_ok());
    assert_eq!(pause.sleeps(), vec![3_000, 10_000]);
}

#[tokio::test]
async fn a_rejected_image_is_not_retried() {
    let (search, http, _) = run(vec![Ok(HttpResponse::new(400, "bad"))]);
    assert_eq!(
        search.find(vec![1]).await,
        Err(SourceError::Unsupported("image was rejected".into()))
    );
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn other_statuses_mean_the_service_is_unavailable() {
    for status in [403, 404, 500, 502] {
        let (search, http, _) = run(vec![Ok(HttpResponse::new(status, ""))]);
        assert_eq!(
            search.find(vec![1]).await,
            Err(SourceError::Unavailable(format!("http {status}")))
        );
        assert_eq!(http.requests().len(), 1);
    }
}

#[tokio::test]
async fn a_reply_that_is_not_json_means_the_format_changed() {
    let (search, _, _) = run(vec![Ok(HttpResponse::new(200, "<html>oops</html>"))]);
    let error = search.find(vec![1]).await.unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[tokio::test]
async fn a_transport_failure_passes_through_without_a_retry() {
    let (search, http, pause) = run(vec![Err(SourceError::Network("offline".into()))]);
    assert_eq!(
        search.find(vec![1]).await,
        Err(SourceError::Network("offline".into()))
    );
    assert_eq!(http.requests().len(), 1);
    assert!(pause.sleeps().is_empty());
}
