use std::sync::{Arc, Mutex, OnceLock};

use application::ports::Clock;
use domain::error::SourceError;

use super::page_cache::PageCache;
use crate::http::{HttpClient, HttpRequest, HttpResponse, ResponseCache};

const SAVED_PAGE_SECS: u64 = 15 * 60;

static SAVED_PAGES: OnceLock<Arc<ResponseCache>> = OnceLock::new();

pub fn share_page_cache(cache: Arc<ResponseCache>) {
    let _ = SAVED_PAGES.set(cache);
}

pub struct PageFetcher {
    http: Arc<dyn HttpClient>,
    clock: Arc<dyn Clock>,
    cache: Mutex<PageCache>,
    saved: Option<Arc<ResponseCache>>,
}

impl PageFetcher {
    pub fn new(http: Arc<dyn HttpClient>, clock: Arc<dyn Clock>) -> Self {
        Self {
            http,
            clock,
            cache: Mutex::new(PageCache::default()),
            saved: None,
        }
    }

    #[cfg(test)]
    pub fn with_saved_pages(mut self, cache: Arc<ResponseCache>) -> Self {
        self.saved = Some(cache);
        self
    }

    fn saved_pages(&self) -> Option<&Arc<ResponseCache>> {
        self.saved.as_ref().or_else(|| SAVED_PAGES.get())
    }

    pub async fn fetch(&self, url: &str) -> Result<String, SourceError> {
        let now = self.clock.now_secs();
        if let Some(body) = self.cache.lock().unwrap().get(url, now) {
            return Ok(body);
        }
        let saved = match self.saved_pages() {
            Some(cache) => cache.lookup(url).await,
            None => None,
        };
        if let Some(hit) = saved.as_ref().filter(|hit| hit.age_secs < SAVED_PAGE_SECS) {
            self.cache.lock().unwrap().put(url, now, hit.body.clone());
            return Ok(hit.body.clone());
        }
        match self.fetch_live(url).await {
            Ok(body) => {
                if let Some(cache) = self.saved_pages() {
                    cache.store(url, &body).await;
                }
                Ok(body)
            }
            Err(error) => saved.map(|stale| stale.body).ok_or(error),
        }
    }

    pub async fn fetch_live(&self, url: &str) -> Result<String, SourceError> {
        let now = self.clock.now_secs();
        if let Some(body) = self.cache.lock().unwrap().get(url, now) {
            return Ok(body);
        }
        let response = self.http.send(HttpRequest::get(url)).await?;
        check_status(&response)?;
        self.cache
            .lock()
            .unwrap()
            .put(url, now, response.body.clone());
        Ok(response.body)
    }

    pub async fn post_form(
        &self,
        url: &str,
        fields: &[(&str, &str)],
    ) -> Result<String, SourceError> {
        let response = self.http.send(HttpRequest::post_form(url, fields)).await?;
        check_status(&response)?;
        Ok(response.body)
    }

    pub async fn post_json(&self, url: &str, body: &str) -> Result<String, SourceError> {
        let response = self.http.send(HttpRequest::post_json(url, body)).await?;
        check_status(&response)?;
        Ok(response.body)
    }
}

fn check_status(response: &HttpResponse) -> Result<(), SourceError> {
    match response.status {
        404 => Err(SourceError::NotFound("the source has no such page".into())),
        429 => Err(SourceError::RateLimited {
            retry_after_secs: response.header_number("retry-after"),
        }),
        403 | 503 if looks_like_a_challenge(&response.body) => Err(SourceError::ChallengeRequired(
            format!("source returned HTTP {}", response.status),
        )),
        _ if response.is_success() => Ok(()),
        status => Err(SourceError::Unavailable(format!(
            "source returned HTTP {status}"
        ))),
    }
}

fn looks_like_a_challenge(body: &str) -> bool {
    let lower = body.to_lowercase();
    [
        "just a moment",
        "cf-chl",
        "challenge-platform",
        "attention required",
    ]
    .iter()
    .any(|marker| lower.contains(marker))
}

#[cfg(test)]
mod tests;

#[cfg(test)]
mod saved_page_tests;
