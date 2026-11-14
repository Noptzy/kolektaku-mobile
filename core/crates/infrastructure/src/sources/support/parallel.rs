use std::sync::Arc;

use domain::error::SourceError;
use tokio::task::JoinSet;

use super::PageFetcher;

pub async fn fetch_all(
    pages: &Arc<PageFetcher>,
    urls: Vec<String>,
) -> Vec<Result<String, SourceError>> {
    let mut tasks = JoinSet::new();
    for (index, url) in urls.iter().cloned().enumerate() {
        let pages = Arc::clone(pages);
        tasks.spawn(async move { (index, pages.fetch(&url).await) });
    }
    let mut results: Vec<Option<Result<String, SourceError>>> = urls.iter().map(|_| None).collect();
    while let Some(joined) = tasks.join_next().await {
        if let Ok((index, result)) = joined {
            results[index] = Some(result);
        }
    }
    results
        .into_iter()
        .map(|result| {
            result.unwrap_or_else(|| Err(SourceError::Network("page task did not finish".into())))
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use application::testing::FakeClock;

    use super::*;
    use crate::http::{FakeHttp, HttpRequest, HttpResponse};

    fn pages_echoing_the_url() -> (Arc<PageFetcher>, Arc<FakeHttp>) {
        let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
            if request.url.ends_with("/missing") {
                Ok(HttpResponse::new(404, ""))
            } else {
                Ok(HttpResponse::new(200, request.url.clone()))
            }
        }));
        let pages = Arc::new(PageFetcher::new(http.clone(), Arc::new(FakeClock::at(0))));
        (pages, http)
    }

    #[tokio::test]
    async fn results_come_back_in_request_order() {
        let (pages, http) = pages_echoing_the_url();
        let urls: Vec<String> = (0..6)
            .map(|index| format!("https://s.test/{index}"))
            .collect();
        let results = fetch_all(&pages, urls.clone()).await;
        let bodies: Vec<String> = results.into_iter().map(Result::unwrap).collect();
        assert_eq!(bodies, urls);
        assert_eq!(http.requests().len(), 6);
    }

    #[tokio::test]
    async fn one_failure_does_not_hide_the_other_pages() {
        let (pages, _) = pages_echoing_the_url();
        let urls = vec![
            "https://s.test/a".to_string(),
            "https://s.test/missing".to_string(),
        ];
        let results = fetch_all(&pages, urls).await;
        assert!(results[0].is_ok());
        assert!(matches!(results[1], Err(SourceError::NotFound(_))));
    }

    #[tokio::test]
    async fn no_urls_means_no_results() {
        let (pages, http) = pages_echoing_the_url();
        assert!(fetch_all(&pages, Vec::new()).await.is_empty());
        assert!(http.requests().is_empty());
    }
}
