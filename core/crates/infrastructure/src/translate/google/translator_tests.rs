use std::sync::Arc;

use application::ports::Translator;
use domain::error::SourceError;
use domain::settings::TranslationLanguage;
use domain::translation::LanguageRoute;

use super::GoogleTranslator;
use crate::fixtures;
use crate::http::{FakeHttp, HttpMethod, HttpResponse};

fn route() -> LanguageRoute {
    LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap()
}

fn translator_replying(response: HttpResponse) -> (GoogleTranslator, Arc<FakeHttp>) {
    let http = Arc::new(FakeHttp::always(response));
    (GoogleTranslator::new(http.clone()), http)
}

#[tokio::test]
async fn the_recorded_reply_becomes_aligned_translations() {
    let (translator, _) = translator_replying(HttpResponse::new(
        200,
        fixtures::translate("auto_multi.json"),
    ));
    let lines = vec![
        "Hello, how are you?".to_string(),
        "Selamat pagi semuanya.".to_string(),
    ];
    let reply = translator.translate(lines, route()).await.unwrap();
    assert!(reply.answers(2));
    assert_eq!(reply.detected_from.as_deref(), Some("en"));
}

#[tokio::test]
async fn one_post_carries_every_line() {
    let (translator, http) = translator_replying(HttpResponse::new(200, "[\"a\",\"b\"]"));
    translator
        .translate(vec!["x".into(), "y".into()], route())
        .await
        .unwrap();
    let requests = http.requests();
    assert_eq!(requests.len(), 1);
    assert_eq!(requests[0].method, HttpMethod::Post);
    assert_eq!(requests[0].body.as_deref(), Some("q=x&q=y"));
}

#[tokio::test]
async fn a_429_is_rate_limited_with_the_wait_it_names() {
    let response = HttpResponse::new(429, "").with_header("retry-after", "30");
    let (translator, http) = translator_replying(response);
    let result = translator.translate(vec!["x".into()], route()).await;
    assert_eq!(
        result,
        Err(SourceError::RateLimited {
            retry_after_secs: Some(30)
        })
    );
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn any_other_failing_status_is_unavailable() {
    for status in [400, 403, 500, 503] {
        let (translator, _) = translator_replying(HttpResponse::new(status, ""));
        let result = translator.translate(vec!["x".into()], route()).await;
        assert_eq!(
            result,
            Err(SourceError::Unavailable(format!("http {status}")))
        );
    }
}

#[tokio::test]
async fn an_unexpected_body_means_the_service_changed() {
    let (translator, _) = translator_replying(HttpResponse::new(200, "<html>consent</html>"));
    let result = translator.translate(vec!["x".into()], route()).await;
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[tokio::test]
async fn a_transport_failure_passes_through_untouched() {
    let http = Arc::new(FakeHttp::replying(|_| {
        Err(SourceError::Network("offline".into()))
    }));
    let translator = GoogleTranslator::new(http.clone());
    let result = translator.translate(vec!["x".into()], route()).await;
    assert_eq!(result, Err(SourceError::Network("offline".into())));
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn a_replaced_endpoint_is_the_one_called() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "[\"a\"]")));
    let translator = GoogleTranslator::with_endpoint(http.clone(), "https://mirror.test/t");
    translator
        .translate(vec!["x".into()], route())
        .await
        .unwrap();
    assert!(http.requests()[0].url.starts_with("https://mirror.test/t?"));
}
