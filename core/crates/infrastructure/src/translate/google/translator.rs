use std::sync::Arc;

use application::ports::{BoxFuture, Translator};
use domain::error::SourceError;
use domain::translation::{LanguageRoute, TranslationReply};

use super::reply::read_reply;
use super::request::{DEFAULT_ENDPOINT, build_request};
use crate::http::HttpClient;

pub struct GoogleTranslator {
    http: Arc<dyn HttpClient>,
    endpoint: String,
}

impl GoogleTranslator {
    pub fn new(http: Arc<dyn HttpClient>) -> Self {
        Self::with_endpoint(http, DEFAULT_ENDPOINT)
    }

    pub fn with_endpoint(http: Arc<dyn HttpClient>, endpoint: impl Into<String>) -> Self {
        Self {
            http,
            endpoint: endpoint.into(),
        }
    }
}

impl Translator for GoogleTranslator {
    fn translate(
        &self,
        lines: Vec<String>,
        route: LanguageRoute,
    ) -> BoxFuture<'_, Result<TranslationReply, SourceError>> {
        Box::pin(async move {
            let request = build_request(&self.endpoint, &lines, &route);
            let response = self.http.send(request).await?;
            match response.status {
                200..=299 => read_reply(&response.body),
                429 => Err(SourceError::RateLimited {
                    retry_after_secs: response.header_number("retry-after"),
                }),
                status => Err(SourceError::Unavailable(format!("http {status}"))),
            }
        })
    }
}
