use std::sync::Arc;
use std::time::Duration;

use crate::error::UpdateError;
use crate::transport::{Body, BoxFuture, Fetched, Transport};

const TIMEOUT: Duration = Duration::from_secs(30);

fn tls_config() -> Result<rustls::ClientConfig, UpdateError> {
    let roots = rustls::RootCertStore::from_iter(webpki_roots::TLS_SERVER_ROOTS.iter().cloned());
    let provider = Arc::new(rustls::crypto::ring::default_provider());
    rustls::ClientConfig::builder_with_provider(provider)
        .with_safe_default_protocol_versions()
        .map_err(|error| UpdateError::Network(error.to_string()))
        .map(|builder| builder.with_root_certificates(roots).with_no_client_auth())
}

fn failure(error: reqwest::Error) -> UpdateError {
    UpdateError::Network(error.without_url().to_string())
}

pub struct ReqwestTransport {
    client: reqwest::Client,
}

impl ReqwestTransport {
    pub fn new() -> Result<Self, UpdateError> {
        let client = reqwest::Client::builder()
            .connect_timeout(TIMEOUT)
            .read_timeout(TIMEOUT)
            .user_agent("kolektaku-updater")
            .use_preconfigured_tls(tls_config()?)
            .build()
            .map_err(failure)?;
        Ok(Self { client })
    }
}

struct ChunkBody(reqwest::Response);

impl Body for ChunkBody {
    fn next(&mut self) -> BoxFuture<'_, Result<Option<Vec<u8>>, UpdateError>> {
        Box::pin(async move {
            let chunk = self.0.chunk().await.map_err(failure)?;
            Ok(chunk.map(|bytes| bytes.to_vec()))
        })
    }
}

impl Transport for ReqwestTransport {
    fn text(&self, url: &str) -> BoxFuture<'_, Result<String, UpdateError>> {
        let url = url.to_string();
        Box::pin(async move {
            let response = self.client.get(&url).send().await.map_err(failure)?;
            if !response.status().is_success() {
                return Err(UpdateError::Network(format!(
                    "answered {}",
                    response.status().as_u16()
                )));
            }
            response.text().await.map_err(failure)
        })
    }

    fn fetch(&self, url: &str, from: u64) -> BoxFuture<'_, Result<Fetched, UpdateError>> {
        let url = url.to_string();
        Box::pin(async move {
            let mut request = self.client.get(&url);
            if from > 0 {
                request = request.header("Range", format!("bytes={from}-"));
            }
            let response = request.send().await.map_err(failure)?;
            Ok(Fetched {
                status: response.status().as_u16(),
                url: response.url().to_string(),
                body: Box::new(ChunkBody(response)),
            })
        })
    }
}
