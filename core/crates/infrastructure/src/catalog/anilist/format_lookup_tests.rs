use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{MediaFormat, MediaId};
use serde_json::json;

use super::catalog_test_support::{
    catalog_failing_with, catalog_replying, sent_query, sent_variables,
};
use crate::http::HttpResponse;

fn id(value: u64) -> MediaId {
    MediaId::new(value).unwrap()
}

fn reply(media: serde_json::Value) -> String {
    json!({ "data": { "Page": { "media": media } } }).to_string()
}

#[tokio::test]
async fn one_request_asks_for_the_formats_of_every_id() {
    let body = reply(json!([
        { "id": 11, "format": "NOVEL" },
        { "id": 12, "format": "MANGA" },
        { "id": 13, "format": null },
    ]));
    let (catalog, http) = catalog_replying(body);
    let found = catalog
        .comic_formats(&[id(11), id(12), id(13)])
        .await
        .unwrap();
    assert_eq!(
        found,
        vec![
            (id(11), Some(MediaFormat::Novel)),
            (id(12), Some(MediaFormat::Manga)),
            (id(13), None),
        ]
    );
    assert_eq!(http.requests().len(), 1);
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["ids"], json!([11, 12, 13]));
    assert_eq!(variables["perPage"], 3);
    assert!(sent_query(&http, 0).contains("id_in: $ids, type: MANGA"));
}

#[tokio::test]
async fn an_unknown_format_name_is_read_as_no_format() {
    let (catalog, _) = catalog_replying(reply(json!([{ "id": 1, "format": "SOMETHING_NEW" }])));
    let found = catalog.comic_formats(&[id(1)]).await.unwrap();
    assert_eq!(found, vec![(id(1), None)]);
}

#[tokio::test]
async fn no_ids_means_no_request() {
    let (catalog, http) = catalog_replying(reply(json!([])));
    assert!(catalog.comic_formats(&[]).await.unwrap().is_empty());
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn a_catalog_outage_is_an_error_and_not_an_empty_answer() {
    let catalog = catalog_failing_with(HttpResponse::new(503, "down"));
    let result = catalog.comic_formats(&[id(1)]).await;
    assert!(matches!(result, Err(SourceError::Unavailable(_))));
}
