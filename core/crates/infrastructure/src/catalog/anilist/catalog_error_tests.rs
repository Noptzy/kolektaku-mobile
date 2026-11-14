use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{MediaId, MediaKind, MediaListKind};

use super::catalog_test_support::{OCTOBER_2026, catalog_failing_with, catalog_over};
use crate::http::{FakeHttp, HttpResponse};

#[tokio::test]
async fn a_graphql_404_on_detail_is_not_found() {
    let body = r#"{"errors":[{"message":"Not Found.","status":404}],"data":{"Media":null}}"#;
    let catalog = catalog_failing_with(HttpResponse::new(404, body));
    let error = catalog
        .detail(MediaKind::Anime, MediaId::new(1).unwrap())
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::NotFound("Not Found.".into()));
}

#[tokio::test]
async fn a_429_is_rate_limited_so_callers_can_keep_what_they_have() {
    let body = r#"{"errors":[{"message":"Too Many Requests.","status":429}]}"#;
    let catalog =
        catalog_failing_with(HttpResponse::new(429, body).with_header("retry-after", "12"));
    let error = catalog
        .list(MediaKind::Anime, MediaListKind::Trending, 1)
        .await
        .unwrap_err();
    assert_eq!(
        error,
        SourceError::RateLimited {
            retry_after_secs: Some(12)
        }
    );
}

#[tokio::test]
async fn a_bad_gateway_page_is_unavailable() {
    let catalog = catalog_failing_with(HttpResponse::new(502, "<html>bad gateway</html>"));
    let error = catalog
        .list(MediaKind::Anime, MediaListKind::Trending, 1)
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}

#[tokio::test]
async fn a_changed_response_shape_is_markup_changed() {
    let catalog = catalog_failing_with(HttpResponse::new(
        200,
        r#"{"data":{"Page":{"media":[{"id":"x"}]}}}"#,
    ));
    let error = catalog
        .list(MediaKind::Anime, MediaListKind::Trending, 1)
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(message) if message.contains("list")));
}

#[tokio::test]
async fn a_detail_with_the_wrong_shape_is_markup_changed() {
    let catalog = catalog_failing_with(HttpResponse::new(200, r#"{"data":{"Media":{"id":5}}}"#));
    let error = catalog
        .detail(MediaKind::Anime, MediaId::new(5).unwrap())
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(message) if message.contains("detail")));
}

#[tokio::test]
async fn transport_failures_become_network_errors() {
    let http = Arc::new(FakeHttp::scripted(vec![Err(SourceError::Network(
        "offline".into(),
    ))]));
    let error = catalog_over(http, OCTOBER_2026)
        .search(MediaKind::Anime, "x", 1)
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::Network("offline".into()));
}
