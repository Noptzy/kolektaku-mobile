use std::sync::Arc;

use domain::error::SourceError;
use domain::source::{ItemId, SourceSearch};

use super::contract::{always, each_site, source_over};
use crate::http::{FakeHttp, HttpResponse};

#[tokio::test]
async fn changed_markup_is_never_a_silent_empty_result() {
    for (registration, _) in each_site() {
        let source = source_over(registration, always(200, "<main>redesigned</main>"));
        let id = registration.defaults.id;
        let item = ItemId::new("1/x");
        let results = [
            source.search(SourceSearch::new("x")).await.map(|_| ()),
            source.latest(1).await.map(|_| ()),
            source.detail(item.clone()).await.map(|_| ()),
            source.units(item).await.map(|_| ()),
        ];
        for result in results {
            assert!(
                matches!(
                    result,
                    Err(SourceError::MarkupChanged(_)) | Err(SourceError::NotFound(_))
                ),
                "{id}: {result:?}"
            );
        }
    }
}

#[tokio::test]
async fn http_failures_map_to_typed_errors() {
    for (registration, _) in each_site() {
        let id = registration.defaults.id;
        let cases = [
            (HttpResponse::new(404, ""), "not found"),
            (HttpResponse::new(502, ""), "unavailable"),
            (
                HttpResponse::new(429, "").with_header("retry-after", "3"),
                "rate limited",
            ),
            (
                HttpResponse::new(403, "<title>Just a moment...</title>"),
                "challenge",
            ),
        ];
        for (response, expected) in cases {
            let source = source_over(registration, Arc::new(FakeHttp::always(response)));
            let error = source.latest(1).await.unwrap_err();
            let matches = match expected {
                "not found" => matches!(error, SourceError::NotFound(_)),
                "unavailable" => matches!(error, SourceError::Unavailable(_)),
                "rate limited" => matches!(
                    error,
                    SourceError::RateLimited {
                        retry_after_secs: Some(3)
                    }
                ),
                _ => matches!(error, SourceError::ChallengeRequired(_)),
            };
            assert!(matches, "{id}: {expected} became {error:?}");
        }
        let offline = Arc::new(FakeHttp::scripted(vec![Err(SourceError::Network(
            "offline".into(),
        ))]));
        let error = source_over(registration, offline)
            .latest(1)
            .await
            .unwrap_err();
        assert_eq!(error, SourceError::Network("offline".into()), "{id}");
    }
}

#[tokio::test]
async fn malformed_ids_are_refused_without_a_request() {
    for (registration, _) in each_site() {
        let http = always(200, "");
        let source = source_over(registration, http.clone());
        let bad = ItemId::new("../x");
        let detail = source.detail(bad.clone()).await;
        let units = source.units(bad).await;
        let id = registration.defaults.id;
        assert!(matches!(detail, Err(SourceError::NotFound(_))), "{id}");
        assert!(matches!(units, Err(SourceError::NotFound(_))), "{id}");
        assert!(http.requests().is_empty(), "{id}");
    }
}

#[tokio::test]
async fn genres_are_either_served_or_declared_unsupported() {
    for (registration, _) in each_site() {
        let source = source_over(registration, always(200, ""));
        let genres = source.genres().await;
        assert!(matches!(
            genres,
            Ok(_) | Err(SourceError::Unsupported(_)) | Err(SourceError::MarkupChanged(_))
        ));
    }
}
