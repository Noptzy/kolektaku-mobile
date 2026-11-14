use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::MediaKind;
use serde_json::json;

use super::catalog_test_support::{
    catalog_failing_with, catalog_replying, sent_query, sent_variables,
};
use crate::http::HttpResponse;

fn genres(names: &[&str]) -> Vec<String> {
    names.iter().map(ToString::to_string).collect()
}

fn reply(data: serde_json::Value) -> String {
    json!({ "data": data }).to_string()
}

#[tokio::test]
async fn one_request_carries_every_genre_under_its_catalog_name() {
    let (catalog, http) = catalog_replying(reply(json!({
        "g0": { "media": [{ "coverImage": { "large": "action-1" } }] },
        "t0": { "media": [] },
        "g1": { "media": [] },
        "t1": { "media": [{ "coverImage": { "large": "food-1" } }] },
    })));
    let found = catalog
        .genre_covers(MediaKind::Anime, &genres(&["Action", "Gourmet"]))
        .await
        .unwrap();
    assert_eq!(found, vec![vec!["action-1"], vec!["food-1"]]);
    assert_eq!(http.requests().len(), 1);
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["type"], "ANIME");
    assert_eq!(variables["n0"], "Action");
    assert_eq!(variables["n1"], "Food");
    assert!(sent_query(&http, 0).contains("t1: Page"));
}

#[tokio::test]
async fn manga_asks_for_the_manga_catalog() {
    let (catalog, http) = catalog_replying(reply(json!({})));
    catalog
        .genre_covers(MediaKind::Manga, &genres(&["Drama"]))
        .await
        .unwrap();
    assert_eq!(sent_variables(&http, 0)["type"], "MANGA");
}

#[tokio::test]
async fn a_genre_the_catalog_does_not_know_has_no_candidates() {
    let (catalog, _) = catalog_replying(reply(json!({
        "g0": { "media": [] },
        "t0": { "media": [] },
    })));
    let found = catalog
        .genre_covers(MediaKind::Anime, &genres(&["Nonexistent"]))
        .await
        .unwrap();
    assert_eq!(found, vec![Vec::<String>::new()]);
}

#[tokio::test]
async fn no_genres_means_no_request() {
    let (catalog, http) = catalog_replying(reply(json!({})));
    let found = catalog.genre_covers(MediaKind::Anime, &[]).await.unwrap();
    assert!(found.is_empty());
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn an_unreadable_answer_is_a_markup_change() {
    let (catalog, _) = catalog_replying(reply(json!({ "g0": "oops" })));
    let error = catalog
        .genre_covers(MediaKind::Anime, &genres(&["Action"]))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[tokio::test]
async fn a_bad_gateway_is_reported() {
    let catalog = catalog_failing_with(HttpResponse::new(502, "<html>bad gateway</html>"));
    let error = catalog
        .genre_covers(MediaKind::Anime, &genres(&["Action"]))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}

fn ok(value: serde_json::Value) -> Result<HttpResponse, SourceError> {
    Ok(HttpResponse::new(200, reply(value)))
}

#[tokio::test]
async fn many_genres_are_asked_in_chunks_that_stay_under_the_complexity_limit() {
    use std::sync::Arc;

    use super::catalog_test_support::{OCTOBER_2026, catalog_over};
    use crate::http::FakeHttp;

    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, reply(json!({})))));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    let names: Vec<String> = (0..60).map(|index| format!("Genre {index}")).collect();
    let found = catalog
        .genre_covers(MediaKind::Anime, &names)
        .await
        .unwrap();
    assert_eq!(found.len(), 60);
    assert_eq!(http.requests().len(), 3);
    for index in 0..3 {
        let aliases = sent_query(&http, index).matches("Page(perPage: 4)").count();
        assert!(aliases * 4 <= 400, "{aliases} aliases in request {index}");
    }
}

#[tokio::test]
async fn one_failing_chunk_keeps_the_covers_of_the_others() {
    use std::sync::Arc;

    use super::catalog_test_support::{OCTOBER_2026, catalog_over};
    use crate::http::FakeHttp;

    let first = ok(json!({
        "g0": { "media": [{ "coverImage": { "large": "first-1" } }] },
    }));
    let second = Ok(HttpResponse::new(502, "<html>bad gateway</html>"));
    let http = Arc::new(FakeHttp::scripted(vec![first, second]));
    let catalog = catalog_over(http, OCTOBER_2026);
    let names: Vec<String> = (0..30).map(|index| format!("Genre {index}")).collect();
    let found = catalog
        .genre_covers(MediaKind::Anime, &names)
        .await
        .unwrap();
    assert_eq!(found.len(), 30);
    assert_eq!(found[0], vec!["first-1"]);
    assert!(found[24..].iter().all(Vec::is_empty));
}

#[tokio::test]
async fn when_every_chunk_fails_the_error_is_reported() {
    let catalog = catalog_failing_with(HttpResponse::new(502, "<html>bad gateway</html>"));
    let names: Vec<String> = (0..30).map(|index| format!("Genre {index}")).collect();
    let error = catalog
        .genre_covers(MediaKind::Anime, &names)
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}
