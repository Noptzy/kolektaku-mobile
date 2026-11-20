use std::sync::Arc;
use std::time::Duration;

use application::ports::BoxFuture;
use domain::error::SourceError;

use super::{HttpClient, HttpMethod, HttpRequest, HttpResponse};

pub const DEFAULT_TIMEOUT: Duration = Duration::from_secs(20);
const FILE_READ_TIMEOUT: Duration = Duration::from_secs(60);
const USER_AGENT: &str = "Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36";

fn tls_config() -> Result<rustls::ClientConfig, SourceError> {
    let roots = rustls::RootCertStore::from_iter(webpki_roots::TLS_SERVER_ROOTS.iter().cloned());
    let provider = Arc::new(rustls::crypto::ring::default_provider());
    let config = rustls::ClientConfig::builder_with_provider(provider)
        .with_safe_default_protocol_versions()
        .map_err(|error| SourceError::Network(error.to_string()))?
        .with_root_certificates(roots)
        .with_no_client_auth();
    Ok(config)
}

pub struct ReqwestClient {
    client: reqwest::Client,
}

impl ReqwestClient {
    pub fn standard() -> Result<Self, SourceError> {
        Self::new(DEFAULT_TIMEOUT)
    }

    pub fn for_files() -> Result<Self, SourceError> {
        let client = reqwest::Client::builder()
            .connect_timeout(DEFAULT_TIMEOUT)
            .read_timeout(FILE_READ_TIMEOUT)
            .user_agent(USER_AGENT)
            .use_preconfigured_tls(tls_config()?)
            .build()
            .map_err(network_error)?;
        Ok(Self { client })
    }

    pub fn new(timeout: Duration) -> Result<Self, SourceError> {
        let client = reqwest::Client::builder()
            .timeout(timeout)
            .user_agent(USER_AGENT)
            .use_preconfigured_tls(tls_config()?)
            .build()
            .map_err(network_error)?;
        Ok(Self { client })
    }

    fn builder(&self, request: HttpRequest) -> reqwest::RequestBuilder {
        let method = match request.method {
            HttpMethod::Get => reqwest::Method::GET,
            HttpMethod::Post => reqwest::Method::POST,
        };
        let mut builder = self.client.request(method, &request.url);
        for (name, value) in &request.headers {
            builder = builder.header(name, value);
        }
        if let Some(bytes) = request.bytes {
            builder = builder.body(bytes);
        } else if let Some(body) = request.body {
            builder = builder.body(body);
        }
        builder
    }

    pub async fn open(&self, request: HttpRequest) -> Result<reqwest::Response, SourceError> {
        self.builder(request).send().await.map_err(network_error)
    }

    async fn execute(&self, request: HttpRequest) -> Result<HttpResponse, SourceError> {
        let builder = self.builder(request);
        let response = builder.send().await.map_err(network_error)?;
        let status = response.status().as_u16();
        let url = response.url().to_string();
        let headers = response
            .headers()
            .iter()
            .filter_map(|(name, value)| {
                Some((name.as_str().to_string(), value.to_str().ok()?.to_string()))
            })
            .collect();
        let body = response.text().await.map_err(network_error)?;
        Ok(HttpResponse {
            status,
            url,
            body,
            headers,
        })
    }
}

pub(crate) fn network_error(error: reqwest::Error) -> SourceError {
    if error.is_timeout() {
        SourceError::Network("request timed out".into())
    } else {
        SourceError::Network(error.without_url().to_string())
    }
}

impl HttpClient for ReqwestClient {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>> {
        Box::pin(self.execute(request))
    }
}
