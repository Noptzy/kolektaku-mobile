use std::sync::Arc;

use application::ports::BoxFuture;
use domain::error::SourceError;

use super::{HttpClient, HttpRequest, HttpResponse, ResponseCache};

pub type TtlPolicy = fn(&HttpRequest) -> Option<u64>;

pub struct CachedHttp {
    inner: Arc<dyn HttpClient>,
    cache: Arc<ResponseCache>,
    ttl_of: TtlPolicy,
}

impl CachedHttp {
    pub fn new(inner: Arc<dyn HttpClient>, cache: Arc<ResponseCache>, ttl_of: TtlPolicy) -> Self {
        Self {
            inner,
            cache,
            ttl_of,
        }
    }
}

fn key_of(request: &HttpRequest) -> String {
    format!(
        "{:?} {}\n{}",
        request.method,
        request.url,
        request.body.as_deref().unwrap_or_default()
    )
}

fn storable(response: &HttpResponse) -> bool {
    response.status == 200 && !response.body.contains("\"errors\"")
}

impl HttpClient for CachedHttp {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>> {
        Box::pin(async move {
            let Some(ttl) = (self.ttl_of)(&request) else {
                return self.inner.send(request).await;
            };
            let key = key_of(&request);
            let cached = self.cache.lookup(&key).await;
            if let Some(hit) = cached.as_ref().filter(|hit| hit.age_secs < ttl) {
                return Ok(HttpResponse::new(200, hit.body.clone()));
            }
            match self.inner.send(request).await {
                Ok(response) => {
                    if storable(&response) {
                        self.cache.store(&key, &response.body).await;
                    }
                    Ok(response)
                }
                Err(error) => match cached {
                    Some(stale) => Ok(HttpResponse::new(200, stale.body)),
                    None => Err(error),
                },
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use application::testing::FakeClock;

    use super::*;
    use crate::http::FakeHttp;
    use crate::storage::TempFolder;

    const TTL: u64 = 100;

    fn policy(request: &HttpRequest) -> Option<u64> {
        request.url.contains("cache-me").then_some(TTL)
    }

    struct Rig {
        _folder: TempFolder,
        clock: Arc<FakeClock>,
        origin: Arc<FakeHttp>,
        client: CachedHttp,
        cache: Arc<ResponseCache>,
    }

    fn rig(label: &str, replies: Vec<Result<HttpResponse, SourceError>>) -> Rig {
        let folder = TempFolder::new(label);
        let clock = Arc::new(FakeClock::at(1000));
        let cache = Arc::new(ResponseCache::new(folder.file("c"), clock.clone(), 50));
        let origin = Arc::new(FakeHttp::scripted(replies));
        let client = CachedHttp::new(origin.clone(), cache.clone(), policy);
        Rig {
            _folder: folder,
            clock,
            origin,
            client,
            cache,
        }
    }

    fn ok(body: &str) -> Result<HttpResponse, SourceError> {
        Ok(HttpResponse::new(200, body))
    }

    fn ask(url: &str) -> HttpRequest {
        HttpRequest::post_json(url, "{\"q\":1}")
    }

    #[tokio::test]
    async fn a_fresh_answer_is_served_without_asking_again() {
        let rig = rig("ch-fresh", vec![ok("first"), ok("second")]);
        let one = rig.client.send(ask("https://x/cache-me")).await.unwrap();
        rig.clock.advance(TTL - 1);
        let two = rig.client.send(ask("https://x/cache-me")).await.unwrap();
        assert_eq!((one.body.as_str(), two.body.as_str()), ("first", "first"));
        assert_eq!(rig.origin.requests().len(), 1);
    }

    #[tokio::test]
    async fn an_expired_answer_is_asked_for_again() {
        let rig = rig("ch-expired", vec![ok("first"), ok("second")]);
        rig.client.send(ask("https://x/cache-me")).await.unwrap();
        rig.clock.advance(TTL);
        let again = rig.client.send(ask("https://x/cache-me")).await.unwrap();
        assert_eq!(again.body, "second");
        assert_eq!(rig.origin.requests().len(), 2);
    }

    #[tokio::test]
    async fn a_different_body_is_a_different_entry() {
        let rig = rig("ch-body", vec![ok("a"), ok("b")]);
        let first = HttpRequest::post_json("https://x/cache-me", "{\"q\":1}");
        let second = HttpRequest::post_json("https://x/cache-me", "{\"q\":2}");
        assert_eq!(rig.client.send(first).await.unwrap().body, "a");
        assert_eq!(rig.client.send(second).await.unwrap().body, "b");
    }

    #[tokio::test]
    async fn requests_the_policy_skips_always_go_out() {
        let rig = rig("ch-skip", vec![ok("one"), ok("two")]);
        rig.client.send(ask("https://x/other")).await.unwrap();
        let again = rig.client.send(ask("https://x/other")).await.unwrap();
        assert_eq!(again.body, "two");
    }

    #[tokio::test]
    async fn failures_and_graphql_errors_are_not_stored() {
        let rig = rig(
            "ch-bad",
            vec![
                Ok(HttpResponse::new(500, "boom")),
                ok("{\"errors\":[{}]}"),
                ok("good"),
            ],
        );
        let url = "https://x/cache-me";
        rig.client.send(ask(url)).await.unwrap();
        rig.client.send(ask(url)).await.unwrap();
        assert_eq!(rig.client.send(ask(url)).await.unwrap().body, "good");
        assert_eq!(rig.origin.requests().len(), 3);
    }

    #[tokio::test]
    async fn an_old_answer_covers_for_a_network_failure() {
        let rig = rig(
            "ch-stale",
            vec![ok("kept"), Err(SourceError::Network("offline".into()))],
        );
        rig.client.send(ask("https://x/cache-me")).await.unwrap();
        rig.clock.advance(TTL * 10);
        let served = rig.client.send(ask("https://x/cache-me")).await.unwrap();
        assert_eq!(served.body, "kept");
    }

    #[tokio::test]
    async fn a_failure_with_nothing_stored_is_passed_on() {
        let rig = rig("ch-none", vec![Err(SourceError::Network("offline".into()))]);
        let error = rig.client.send(ask("https://x/cache-me")).await;
        assert_eq!(error, Err(SourceError::Network("offline".into())));
    }

    #[tokio::test]
    async fn clearing_the_cache_forces_a_new_request() {
        let rig = rig("ch-clear", vec![ok("one"), ok("two")]);
        rig.client.send(ask("https://x/cache-me")).await.unwrap();
        rig.cache.clear().await;
        let again = rig.client.send(ask("https://x/cache-me")).await.unwrap();
        assert_eq!(again.body, "two");
    }
}
