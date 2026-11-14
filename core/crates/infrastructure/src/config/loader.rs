use std::sync::Arc;

use super::merge::{Defaults, Merged, merge};
use super::model::RemoteConfig;
use super::store::ConfigStore;
use crate::http::{HttpClient, HttpRequest};

pub struct ConfigLoader {
    http: Arc<dyn HttpClient>,
    store: Arc<dyn ConfigStore>,
    url: String,
}

impl ConfigLoader {
    pub fn new(
        http: Arc<dyn HttpClient>,
        store: Arc<dyn ConfigStore>,
        url: impl Into<String>,
    ) -> Self {
        Self {
            http,
            store,
            url: url.into(),
        }
    }

    pub async fn cached(&self) -> Option<RemoteConfig> {
        self.store
            .read()
            .await
            .and_then(|text| RemoteConfig::parse(&text))
    }

    pub async fn refresh(&self) -> Option<RemoteConfig> {
        let text = self.download().await?;
        let config = RemoteConfig::parse(&text)?;
        self.store.write(text).await;
        Some(config)
    }

    pub async fn load(&self) -> Option<RemoteConfig> {
        match self.refresh().await {
            Some(config) => Some(config),
            None => self.cached().await,
        }
    }

    pub async fn resolve(&self, defaults: &[Defaults]) -> Merged {
        merge(defaults, self.load().await.as_ref())
    }

    async fn download(&self) -> Option<String> {
        let response = self.http.send(HttpRequest::get(&self.url)).await.ok()?;
        response.is_success().then_some(response.body)
    }
}
