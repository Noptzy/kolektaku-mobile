use std::sync::{Arc, Mutex};

use application::ports::BoxFuture;
use domain::error::SourceError;

use super::loader::ConfigLoader;
use super::merge::Defaults;
use super::store::ConfigStore;
use crate::http::{FakeHttp, HttpResponse};

const SITE: Defaults = Defaults {
    id: "site",
    base_url: "https://v1.site.example",
    api_url: None,
    priority: 1,
    allowed_hosts: &["*.site.example"],
};

const URL: &str = "https://downloads.example/config.json";

#[derive(Default)]
struct MemoryStore {
    text: Mutex<Option<String>>,
}

impl MemoryStore {
    fn holding(text: &str) -> Arc<Self> {
        Arc::new(Self {
            text: Mutex::new(Some(text.to_string())),
        })
    }

    fn content(&self) -> Option<String> {
        self.text.lock().unwrap().clone()
    }
}

impl ConfigStore for MemoryStore {
    fn read(&self) -> BoxFuture<'_, Option<String>> {
        Box::pin(async move { self.text.lock().unwrap().clone() })
    }

    fn write(&self, text: String) -> BoxFuture<'_, ()> {
        Box::pin(async move { *self.text.lock().unwrap() = Some(text) })
    }
}

const MOVED: &str =
    r#"{"version":1,"sources":[{"id":"site","baseUrl":"https://v2.site.example","priority":4}]}"#;
const STALE: &str =
    r#"{"version":1,"sources":[{"id":"site","baseUrl":"https://v3.site.example"}]}"#;

fn loader(reply: Result<HttpResponse, SourceError>, store: Arc<MemoryStore>) -> ConfigLoader {
    ConfigLoader::new(Arc::new(FakeHttp::scripted(vec![reply])), store, URL)
}

#[tokio::test]
async fn a_downloaded_file_is_applied_and_remembered() {
    let store = Arc::new(MemoryStore::default());
    let merged = loader(Ok(HttpResponse::new(200, MOVED)), store.clone())
        .resolve(&[SITE])
        .await;
    assert_eq!(merged.settings[0].base_url, "https://v2.site.example");
    assert_eq!(merged.settings[0].priority, 4);
    assert_eq!(store.content().as_deref(), Some(MOVED));
}

#[tokio::test]
async fn offline_the_remembered_file_is_used() {
    let store = MemoryStore::holding(STALE);
    let merged = loader(Err(SourceError::Network("offline".into())), store)
        .resolve(&[SITE])
        .await;
    assert_eq!(merged.settings[0].base_url, "https://v3.site.example");
}

#[tokio::test]
async fn a_broken_download_never_replaces_the_remembered_file() {
    let store = MemoryStore::holding(STALE);
    let merged = loader(
        Ok(HttpResponse::new(200, "<html>captive portal</html>")),
        store.clone(),
    )
    .resolve(&[SITE])
    .await;
    assert_eq!(merged.settings[0].base_url, "https://v3.site.example");
    assert_eq!(store.content().as_deref(), Some(STALE));
}

#[tokio::test]
async fn an_error_status_falls_back_to_the_remembered_file() {
    let store = MemoryStore::holding(STALE);
    let merged = loader(Ok(HttpResponse::new(404, MOVED)), store)
        .resolve(&[SITE])
        .await;
    assert_eq!(merged.settings[0].base_url, "https://v3.site.example");
}

#[tokio::test]
async fn with_nothing_at_all_the_embedded_defaults_apply() {
    let store = Arc::new(MemoryStore::default());
    let merged = loader(Err(SourceError::Network("offline".into())), store)
        .resolve(&[SITE])
        .await;
    assert_eq!(merged.settings[0].base_url, "https://v1.site.example");
    assert!(merged.settings[0].enabled);
}

#[tokio::test]
async fn a_remembered_file_that_no_longer_parses_is_ignored() {
    let store = MemoryStore::holding("garbage");
    let merged = loader(Err(SourceError::Network("offline".into())), store)
        .resolve(&[SITE])
        .await;
    assert_eq!(merged.settings[0].base_url, "https://v1.site.example");
}

#[tokio::test]
async fn cached_reads_only_the_remembered_file_and_refresh_only_the_network() {
    let store = MemoryStore::holding(STALE);
    let loader = loader(Ok(HttpResponse::new(200, MOVED)), store.clone());
    assert!(
        loader.cached().await.unwrap().sources[0]
            .base_url
            .as_deref()
            == Some("https://v3.site.example")
    );
    assert_eq!(store.content().as_deref(), Some(STALE));
    assert!(loader.refresh().await.is_some());
    assert_eq!(store.content().as_deref(), Some(MOVED));
}

#[tokio::test]
async fn refresh_without_a_usable_download_leaves_the_store_alone() {
    let store = MemoryStore::holding(STALE);
    let loader = loader(Ok(HttpResponse::new(200, "nope")), store.clone());
    assert!(loader.refresh().await.is_none());
    assert_eq!(store.content().as_deref(), Some(STALE));
}
