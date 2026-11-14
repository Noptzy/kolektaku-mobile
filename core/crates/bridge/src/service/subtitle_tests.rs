use std::sync::Mutex;

use application::ports::BoxFuture;
use domain::error::SourceError;
use infrastructure::http::{HttpClient, HttpRequest, HttpResponse};

use super::service_support::{Folder, state_with};
use super::subtitle::cues;
use crate::dto::stream::HeaderDto;
use crate::error::BridgeErrorKind;

struct Recording {
    reply: Result<HttpResponse, SourceError>,
    seen: Mutex<Vec<HttpRequest>>,
}

impl HttpClient for Recording {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>> {
        self.seen.lock().unwrap().push(request);
        let reply = self.reply.clone();
        Box::pin(async move { reply })
    }
}

fn header(name: &str, value: &str) -> HeaderDto {
    HeaderDto {
        name: name.into(),
        value: value.into(),
    }
}

async fn state_over(
    folder: &Folder,
    reply: Result<HttpResponse, SourceError>,
) -> (
    crate::state::AppState<application::testing::FakeCatalog>,
    std::sync::Arc<Recording>,
) {
    let recording = std::sync::Arc::new(Recording {
        reply,
        seen: Mutex::new(Vec::new()),
    });
    let mut state = state_with(folder, Vec::new(), super::service_support::offline()).await;
    state.http = recording.clone();
    (state, recording)
}

const FILE: &str =
    "WEBVTT\n\n00:12.095 --> 00:16.015\nHalo dunia\n\n00:20.000 --> 00:21.000\nSampai jumpa\n";

#[tokio::test]
async fn the_file_is_fetched_with_only_the_forwarded_headers_and_parsed() {
    let folder = Folder::new();
    let (state, recording) = state_over(&folder, Ok(HttpResponse::new(200, FILE))).await;
    let found = cues(
        &state,
        "https://subs.test/a.vtt",
        &[
            header("Referer", "https://player.test/"),
            header("origin", "https://player.test"),
            header("cookie", "secret=1"),
            header("authorization", "Bearer x"),
        ],
    )
    .await
    .unwrap();
    assert_eq!(found.len(), 2);
    assert_eq!((found[0].start_ms, found[0].end_ms), (12_095, 16_015));
    assert_eq!(found[0].text, "Halo dunia");
    let seen = recording.seen.lock().unwrap();
    assert_eq!(seen[0].url, "https://subs.test/a.vtt");
    assert_eq!(seen[0].header("referer"), Some("https://player.test/"));
    assert_eq!(seen[0].header("origin"), Some("https://player.test"));
    assert_eq!(seen[0].header("cookie"), None);
    assert_eq!(seen[0].header("authorization"), None);
}

#[tokio::test]
async fn an_address_that_is_not_https_is_never_requested() {
    let folder = Folder::new();
    let (state, recording) = state_over(&folder, Ok(HttpResponse::new(200, FILE))).await;
    for bad in [
        "http://subs.test/a.vtt",
        "file:///etc/passwd",
        "javascript:x",
        "",
        "https://",
    ] {
        let error = cues(&state, bad, &[]).await.unwrap_err();
        assert_eq!(error.kind, BridgeErrorKind::NotFound, "{bad:?}");
    }
    assert!(recording.seen.lock().unwrap().is_empty());
}

#[tokio::test]
async fn failures_map_to_typed_errors() {
    let folder = Folder::new();
    let (state, _) = state_over(&folder, Ok(HttpResponse::new(404, ""))).await;
    assert_eq!(
        cues(&state, "https://subs.test/a.vtt", &[])
            .await
            .unwrap_err()
            .kind,
        BridgeErrorKind::NotFound
    );
    let (state, _) = state_over(&folder, Ok(HttpResponse::new(500, ""))).await;
    assert_eq!(
        cues(&state, "https://subs.test/a.vtt", &[])
            .await
            .unwrap_err()
            .kind,
        BridgeErrorKind::Unavailable
    );
    let (state, _) = state_over(&folder, Err(SourceError::Network("down".into()))).await;
    assert_eq!(
        cues(&state, "https://subs.test/a.vtt", &[])
            .await
            .unwrap_err()
            .kind,
        BridgeErrorKind::Network
    );
}

#[tokio::test]
async fn a_file_that_is_not_a_subtitle_gives_no_cues() {
    let folder = Folder::new();
    let (state, _) = state_over(&folder, Ok(HttpResponse::new(200, "<html>oops</html>"))).await;
    assert!(
        cues(&state, "https://subs.test/a.vtt", &[])
            .await
            .unwrap()
            .is_empty()
    );
}
