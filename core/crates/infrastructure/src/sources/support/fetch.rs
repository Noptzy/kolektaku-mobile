use std::sync::{Arc, Mutex};

use application::ports::Clock;
use domain::error::SourceError;

use super::page_cache::PageCache;
use crate::http::{HttpClient, HttpRequest, HttpResponse};

pub struct PageFetcher {
    http: Arc<dyn HttpClient>,
    clock: Arc<dyn Clock>,
    cache: Mutex<PageCache>,
}

impl PageFetcher {
    pub fn new(http: Arc<dyn HttpClient>, clock: Arc<dyn Clock>) -> Self {
        Self {
            http,
            clock,
            cache: Mutex::new(PageCache::default()),
        }
    }

    pub async fn fetch(&self, url: &str) -> Result<String, SourceError> {
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
mod tests {
    use application::testing::FakeClock;

    use super::*;
    use crate::http::FakeHttp;

    fn fetcher(
        replies: Vec<Result<HttpResponse, SourceError>>,
    ) -> (PageFetcher, Arc<FakeHttp>, Arc<FakeClock>) {
        let http = Arc::new(FakeHttp::scripted(replies));
        let clock = Arc::new(FakeClock::at(1_000));
        (PageFetcher::new(http.clone(), clock.clone()), http, clock)
    }

    fn page(body: &str) -> Result<HttpResponse, SourceError> {
        Ok(HttpResponse::new(200, body))
    }

    #[tokio::test]
    async fn a_page_is_fetched_once_within_two_minutes() {
        let (fetcher, http, clock) = fetcher(vec![page("first"), page("second")]);
        assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "first");
        assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "first");
        assert_eq!(http.requests().len(), 1);
        clock.advance(121);
        assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "second");
        assert_eq!(http.requests().len(), 2);
    }

    #[tokio::test]
    async fn failures_are_not_cached() {
        let (fetcher, http, _) = fetcher(vec![Ok(HttpResponse::new(500, "")), page("ok")]);
        assert!(fetcher.fetch("https://s.test/a").await.is_err());
        assert_eq!(fetcher.fetch("https://s.test/a").await.unwrap(), "ok");
        assert_eq!(http.requests().len(), 2);
    }

    #[tokio::test]
    async fn a_json_post_sends_the_body_is_not_cached_and_maps_errors() {
        let (fetcher, http, _) =
            fetcher(vec![page("{}"), page("{}"), Ok(HttpResponse::new(404, ""))]);
        let url = "https://s.test/api/filter";
        assert_eq!(fetcher.post_json(url, "{\"a\":1}").await.unwrap(), "{}");
        assert_eq!(fetcher.post_json(url, "{\"a\":1}").await.unwrap(), "{}");
        let sent = http.requests();
        assert_eq!(sent.len(), 2);
        assert_eq!(sent[0].body.as_deref(), Some("{\"a\":1}"));
        assert_eq!(sent[0].header("content-type"), Some("application/json"));
        assert!(matches!(
            fetcher.post_json(url, "{}").await,
            Err(SourceError::NotFound(_))
        ));
    }

    async fn error_for(response: HttpResponse) -> SourceError {
        let (fetcher, _, _) = fetcher(vec![Ok(response)]);
        fetcher.fetch("https://s.test/a").await.unwrap_err()
    }

    #[tokio::test]
    async fn statuses_map_to_the_matching_source_error() {
        assert!(matches!(
            error_for(HttpResponse::new(404, "")).await,
            SourceError::NotFound(_)
        ));
        assert!(matches!(
            error_for(HttpResponse::new(502, "")).await,
            SourceError::Unavailable(_)
        ));
        assert!(matches!(
            error_for(HttpResponse::new(403, "plain")).await,
            SourceError::Unavailable(_)
        ));
        let limited = HttpResponse::new(429, "").with_header("retry-after", "9");
        assert_eq!(
            error_for(limited).await,
            SourceError::RateLimited {
                retry_after_secs: Some(9)
            }
        );
    }

    #[tokio::test]
    async fn a_cloudflare_style_block_needs_a_challenge() {
        let blocked = HttpResponse::new(403, "<title>Just a moment...</title>");
        assert!(matches!(
            error_for(blocked).await,
            SourceError::ChallengeRequired(_)
        ));
        let unavailable = HttpResponse::new(503, "<div class=\"cf-chl-widget\">");
        assert!(matches!(
            error_for(unavailable).await,
            SourceError::ChallengeRequired(_)
        ));
    }

    #[tokio::test]
    async fn transport_errors_pass_through() {
        let (fetcher, _, _) = fetcher(vec![Err(SourceError::Network("offline".into()))]);
        assert_eq!(
            fetcher.fetch("https://s.test/a").await.unwrap_err(),
            SourceError::Network("offline".into())
        );
    }
}
