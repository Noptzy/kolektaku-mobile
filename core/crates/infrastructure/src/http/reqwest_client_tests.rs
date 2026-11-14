use std::time::Duration;

use domain::error::SourceError;

use super::local_server::{Behavior, LocalServer};
use super::{HttpClient, HttpRequest, ReqwestClient};

fn client(timeout_millis: u64) -> ReqwestClient {
    ReqwestClient::new(Duration::from_millis(timeout_millis)).unwrap()
}

#[tokio::test]
async fn get_sends_the_custom_headers_and_reads_status_and_response_headers() {
    let server = LocalServer::start(Behavior::Echo {
        extra_header: Some("x-ratelimit-remaining: 42"),
    })
    .await;
    let request = HttpRequest::get(format!("{}/path?q=1", server.base_url))
        .with_header("Referer", "https://origin.test/");
    let response = client(2_000).send(request).await.unwrap();
    assert_eq!(response.status, 200);
    assert_eq!(response.header_number("x-ratelimit-remaining"), Some(42));
    assert!(response.body.starts_with("GET /path?q=1 HTTP/1.1"));
    assert!(
        response
            .body
            .to_lowercase()
            .contains("referer: https://origin.test/")
    );
    assert!(response.url.ends_with("/path?q=1"));
}

#[tokio::test]
async fn post_sends_the_json_body() {
    let server = LocalServer::start(Behavior::Echo { extra_header: None }).await;
    let request =
        HttpRequest::post_json(format!("{}/graphql", server.base_url), r#"{"query":"{x}"}"#);
    let response = client(2_000).send(request).await.unwrap();
    assert!(response.body.starts_with("POST /graphql HTTP/1.1"));
    assert!(
        response
            .body
            .to_lowercase()
            .contains("content-type: application/json")
    );
    assert!(response.body.ends_with(r#"{"query":"{x}"}"#));
}

#[tokio::test]
async fn a_server_that_never_answers_ends_in_a_network_error() {
    let server = LocalServer::start(Behavior::Silent).await;
    let error = client(150)
        .send(HttpRequest::get(server.base_url.clone()))
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::Network("request timed out".into()));
}

#[tokio::test]
async fn an_unreachable_host_ends_in_a_network_error() {
    let error = client(1_000)
        .send(HttpRequest::get("http://127.0.0.1:1/"))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Network(_)));
}

#[test]
fn the_standard_client_can_be_built() {
    assert!(ReqwestClient::standard().is_ok());
}

#[test]
fn the_tls_setup_trusts_the_bundled_roots_without_the_platform() {
    assert!(webpki_roots::TLS_SERVER_ROOTS.len() > 100);
    assert!(ReqwestClient::new(Duration::from_secs(1)).is_ok());
}
