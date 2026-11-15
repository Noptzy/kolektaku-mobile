use std::sync::Arc;

use application::ports::{BoxFuture, Clock, TranslationHealth, Translator};
use domain::error::SourceError;
use domain::translation::{LanguageRoute, TranslationReply};
use serde::{Deserialize, Serialize};

use super::pause_after_failures::{PAUSE_SECS, PauseAfterFailures, ServiceState};
use crate::http::ResponseCache;

pub const CACHE_CAPACITY: usize = 300;

#[derive(Serialize, Deserialize)]
struct Remembered {
    lines: Vec<String>,
    detected_from: Option<String>,
}

pub struct CachedTranslator {
    inner: Arc<dyn Translator>,
    cache: Arc<ResponseCache>,
    clock: Arc<dyn Clock>,
    pause: PauseAfterFailures,
}

impl CachedTranslator {
    pub fn new(
        inner: Arc<dyn Translator>,
        cache: Arc<ResponseCache>,
        clock: Arc<dyn Clock>,
    ) -> Self {
        Self {
            inner,
            cache,
            clock,
            pause: PauseAfterFailures::new(),
        }
    }

    pub fn service_state(&self) -> ServiceState {
        self.pause.state_at(self.clock.now_secs())
    }

    async fn remembered(&self, key: &str) -> Option<TranslationReply> {
        let hit = self.cache.lookup(key).await?;
        let saved: Remembered = serde_json::from_str(&hit.body).ok()?;
        Some(TranslationReply::new(saved.lines, saved.detected_from))
    }

    async fn remember(&self, key: &str, reply: &TranslationReply) {
        let saved = Remembered {
            lines: reply.lines.clone(),
            detected_from: reply.detected_from.clone(),
        };
        if let Ok(body) = serde_json::to_string(&saved) {
            self.cache.store(key, &body).await;
        }
    }

    async fn ask_the_service(
        &self,
        key: &str,
        lines: Vec<String>,
        route: LanguageRoute,
    ) -> Result<TranslationReply, SourceError> {
        let now = self.clock.now_secs();
        if let ServiceState::PausedUntil(until) = self.pause.state_at(now) {
            return Err(SourceError::RateLimited {
                retry_after_secs: Some(until.saturating_sub(now).min(PAUSE_SECS)),
            });
        }
        let asked = lines.len();
        match self.inner.translate(lines, route).await {
            Ok(reply) => {
                self.pause.record_success();
                if reply.answers(asked) {
                    self.remember(key, &reply).await;
                }
                Ok(reply)
            }
            Err(error) => {
                self.pause.record_failure(self.clock.now_secs());
                Err(error)
            }
        }
    }
}

impl TranslationHealth for CachedTranslator {
    fn paused_until(&self) -> Option<u64> {
        match self.service_state() {
            ServiceState::Normal => None,
            ServiceState::PausedUntil(until) => Some(until),
        }
    }
}

pub fn cache_key(lines: &[String], route: &LanguageRoute) -> String {
    format!(
        "translate\u{1}{}\u{1}{}\u{1}{}",
        route.target_code(),
        route.from_code().unwrap_or("auto"),
        lines.join("\u{0}")
    )
}

impl Translator for CachedTranslator {
    fn translate(
        &self,
        lines: Vec<String>,
        route: LanguageRoute,
    ) -> BoxFuture<'_, Result<TranslationReply, SourceError>> {
        Box::pin(async move {
            let key = cache_key(&lines, &route);
            if let Some(reply) = self.remembered(&key).await
                && reply.answers(lines.len())
            {
                return Ok(reply);
            }
            self.ask_the_service(&key, lines, route).await
        })
    }
}
