use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::MediaKind;
use serde_json::{Value, json};

use super::catalog_test_support::{OCTOBER_2026, catalog_over, sent_query};
use super::matching::MATCH_CHUNK;
use crate::fixtures;
use crate::http::{FakeHttp, HttpResponse};

fn titles(count: usize) -> Vec<String> {
    (0..count).map(|index| format!("Judul {index}")).collect()
}

fn answer_for(count: usize) -> String {
    let mut data = serde_json::Map::new();
    for index in 0..count {
        data.insert(format!("m{index}"), json!({ "media": [] }));
    }
    json!({ "data": Value::Object(data) }).to_string()
}

#[tokio::test]
async fn forty_titles_are_asked_in_several_requests_that_each_fit_the_limit() {
    let http = Arc::new(FakeHttp::replying(|request| {
        let body: Value = serde_json::from_str(request.body.as_deref().unwrap()).unwrap();
        let count = body["variables"]
            .as_object()
            .unwrap()
            .keys()
            .filter(|key| key.starts_with('t'))
            .count();
        Ok(HttpResponse::new(200, answer_for(count)))
    }));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    let found = catalog
        .match_titles(MediaKind::Manga, &titles(40))
        .await
        .unwrap();
    assert_eq!(found.len(), 40);
    assert_eq!(http.requests().len(), 40usize.div_ceil(MATCH_CHUNK));
    for index in 0..http.requests().len() {
        let aliases = sent_query(&http, index).matches("Page(perPage: 3)").count();
        assert!(
            aliases <= MATCH_CHUNK,
            "{aliases} aliases in request {index}"
        );
    }
}

#[tokio::test]
async fn the_answers_keep_the_order_of_the_titles_across_requests() {
    let mut body: Value = serde_json::from_str(&fixtures::anilist("batch-anime.json")).unwrap();
    let first = body["data"]["m0"].take();
    let http = Arc::new(FakeHttp::scripted(vec![
        Ok(HttpResponse::new(
            200,
            json!({ "data": { "m0": first } }).to_string(),
        )),
        Ok(HttpResponse::new(200, answer_for(1))),
    ]));
    let catalog = catalog_over(http, OCTOBER_2026);
    let mut asked = titles(MATCH_CHUNK);
    asked.push("zzz".into());
    let found = catalog
        .match_titles(MediaKind::Anime, &asked)
        .await
        .unwrap();
    assert_eq!(found.len(), MATCH_CHUNK + 1);
    assert!(!found[0].is_empty());
    assert!(found[MATCH_CHUNK].is_empty());
}

#[tokio::test]
async fn one_failing_request_only_costs_its_own_titles() {
    let http = Arc::new(FakeHttp::scripted(vec![
        Ok(HttpResponse::new(200, answer_for(MATCH_CHUNK))),
        Ok(HttpResponse::new(502, "<html>bad gateway</html>")),
    ]));
    let catalog = catalog_over(http, OCTOBER_2026);
    let found = catalog
        .match_titles(MediaKind::Anime, &titles(MATCH_CHUNK + 5))
        .await
        .unwrap();
    assert_eq!(found.len(), MATCH_CHUNK + 5);
    assert!(found.iter().all(Vec::is_empty));
}

#[tokio::test]
async fn when_every_request_fails_the_error_is_reported() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        502,
        "<html>bad gateway</html>",
    )));
    let catalog = catalog_over(http, OCTOBER_2026);
    let error = catalog
        .match_titles(MediaKind::Anime, &titles(MATCH_CHUNK + 1))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}

#[tokio::test]
async fn a_batch_that_fits_stays_one_request() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        answer_for(MATCH_CHUNK),
    )));
    let catalog = catalog_over(http.clone(), OCTOBER_2026);
    catalog
        .match_titles(MediaKind::Anime, &titles(MATCH_CHUNK))
        .await
        .unwrap();
    assert_eq!(http.requests().len(), 1);
}
