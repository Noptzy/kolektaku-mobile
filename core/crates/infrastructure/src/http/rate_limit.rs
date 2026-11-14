use std::sync::{Arc, Mutex};

use application::ports::BoxFuture;
use domain::error::SourceError;

use super::{HttpClient, HttpRequest, HttpResponse, Pause};

const MAX_WAIT_MILLIS: u64 = 65_000;
const DEFAULT_RETRY_AFTER_SECS: u64 = 60;
const DEFAULT_RESET_WAIT_MILLIS: u64 = 10_000;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RateLimitSettings {
    pub min_remaining: u64,
    pub max_retries: u32,
}

impl Default for RateLimitSettings {
    fn default() -> Self {
        Self {
            min_remaining: 5,
            max_retries: 1,
        }
    }
}

pub struct RateLimitedClient {
    inner: Arc<dyn HttpClient>,
    pause: Arc<dyn Pause>,
    settings: RateLimitSettings,
    blocked_until: Mutex<u64>,
}

impl RateLimitedClient {
    pub fn new(
        inner: Arc<dyn HttpClient>,
        pause: Arc<dyn Pause>,
        settings: RateLimitSettings,
    ) -> Self {
        Self {
            inner,
            pause,
            settings,
            blocked_until: Mutex::new(0),
        }
    }

    async fn wait_for_window(&self) {
        loop {
            let until = *self.blocked_until.lock().unwrap();
            let remaining = until.saturating_sub(self.pause.now_millis());
            if remaining == 0 {
                return;
            }
            self.pause.sleep(remaining.min(MAX_WAIT_MILLIS)).await;
        }
    }

    fn observe(&self, response: &HttpResponse) {
        let now = self.pause.now_millis();
        if response.status == 429 {
            let seconds = response
                .header_number("retry-after")
                .unwrap_or(DEFAULT_RETRY_AFTER_SECS);
            self.block_until(now + seconds * 1000);
            return;
        }
        let Some(remaining) = response.header_number("x-ratelimit-remaining") else {
            return;
        };
        if remaining >= self.settings.min_remaining {
            return;
        }
        let reset = response
            .header_number("x-ratelimit-reset")
            .map_or(now + DEFAULT_RESET_WAIT_MILLIS, |secs| secs * 1000);
        self.block_until(reset);
    }

    fn block_until(&self, time: u64) {
        let limit = self.pause.now_millis() + MAX_WAIT_MILLIS;
        let mut until = self.blocked_until.lock().unwrap();
        *until = (*until).max(time.min(limit));
    }

    async fn send_with_retries(&self, request: HttpRequest) -> Result<HttpResponse, SourceError> {
        self.wait_for_window().await;
        let mut response = self.inner.send(request.clone()).await?;
        self.observe(&response);
        let mut retries = 0;
        while response.status == 429 && retries < self.settings.max_retries {
            retries += 1;
            self.wait_for_window().await;
            response = self.inner.send(request.clone()).await?;
            self.observe(&response);
        }
        Ok(response)
    }
}

impl HttpClient for RateLimitedClient {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>> {
        Box::pin(self.send_with_retries(request))
    }
}
