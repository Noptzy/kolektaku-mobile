use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::ProfileKind;
use serde_json::{Value, json};

use super::catalog_test_support::{
    catalog_failing_with, catalog_replying, sent_query, sent_variables,
};
use crate::http::HttpResponse;

fn work(english: Option<&str>, romaji: &str, adult: bool) -> Value {
    json!({ "nodes": [{ "title": { "english": english, "romaji": romaji }, "isAdult": adult }] })
}

fn characters_reply() -> String {
    json!({ "data": { "Page": { "characters": [
        { "id": 127518, "name": { "full": "Nezuko Kamado", "native": "竈門禰豆子" },
          "image": { "large": "https://img.test/nezuko.png" },
          "media": work(Some("Demon Slayer"), "Kimetsu no Yaiba", false) },
        { "id": 5, "name": { "full": "Tanpa Gambar", "native": null }, "image": null,
          "media": work(None, "Judul Romaji", false) },
        { "id": 9, "name": { "full": "Karakter Dewasa" }, "image": null,
          "media": work(Some("Dewasa"), "Dewasa", true) },
        { "id": 11, "name": { "full": "Tanpa Karya" }, "image": null, "media": { "nodes": [] } },
    ] } } })
    .to_string()
}

fn staff_reply() -> String {
    json!({ "data": { "Page": { "staff": [
        { "id": 95061, "name": { "full": "Chiwa Saitou", "native": "" },
          "image": { "large": "https://img.test/chiwa.jpg" },
          "primaryOccupations": ["Voice Actor", "", "Singer"] },
        { "id": 3, "name": { "full": null, "native": "名無し" }, "image": null,
          "primaryOccupations": [] },
    ] } } })
    .to_string()
}

fn studios_reply() -> String {
    json!({ "data": { "Page": { "studios": [
        { "id": 858, "name": "Wit Studio", "media": work(Some("Attack on Titan"), "Shingeki", false) },
        { "id": 1, "name": "Studio Kosong", "media": { "nodes": [] } },
    ] } } })
    .to_string()
}

#[tokio::test]
async fn characters_come_with_their_picture_and_best_known_work() {
    let (catalog, http) = catalog_replying(characters_reply());
    let found = catalog
        .search_profiles(ProfileKind::Character, "nezuko")
        .await
        .unwrap();
    assert_eq!(found[0].id, 127518);
    assert_eq!(found[0].kind, ProfileKind::Character);
    assert_eq!(found[0].name, "Nezuko Kamado");
    assert_eq!(
        found[0].image_url.as_deref(),
        Some("https://img.test/nezuko.png")
    );
    assert_eq!(found[0].subtitle.as_deref(), Some("Demon Slayer"));
    assert_eq!(sent_variables(&http, 0)["search"], "nezuko");
    assert!(sent_query(&http, 0).contains("characters(search: $search"));
}

#[tokio::test]
async fn a_character_without_an_english_title_falls_back_to_romaji() {
    let (catalog, _) = catalog_replying(characters_reply());
    let found = catalog
        .search_profiles(ProfileKind::Character, "x")
        .await
        .unwrap();
    assert_eq!(found[1].subtitle.as_deref(), Some("Judul Romaji"));
    assert_eq!(found[1].image_url, None);
}

#[tokio::test]
async fn a_character_from_an_adult_work_is_never_listed() {
    let (catalog, _) = catalog_replying(characters_reply());
    let found = catalog
        .search_profiles(ProfileKind::Character, "x")
        .await
        .unwrap();
    assert!(found.iter().all(|item| item.id != 9));
    assert_eq!(found.len(), 3);
}

#[tokio::test]
async fn a_character_without_any_work_has_no_subtitle() {
    let (catalog, _) = catalog_replying(characters_reply());
    let found = catalog
        .search_profiles(ProfileKind::Character, "x")
        .await
        .unwrap();
    assert_eq!(found.last().unwrap().subtitle, None);
}

#[tokio::test]
async fn staff_show_their_occupations() {
    let (catalog, http) = catalog_replying(staff_reply());
    let found = catalog
        .search_profiles(ProfileKind::Staff, "chiwa")
        .await
        .unwrap();
    assert_eq!(found[0].subtitle.as_deref(), Some("Voice Actor, Singer"));
    assert_eq!(found[1].name, "名無し");
    assert_eq!(found[1].subtitle, None);
    assert!(sent_query(&http, 0).contains("staff(search: $search"));
}

#[tokio::test]
async fn studios_have_a_plain_name_and_their_main_work() {
    let (catalog, http) = catalog_replying(studios_reply());
    let found = catalog
        .search_profiles(ProfileKind::Studio, "wit")
        .await
        .unwrap();
    assert_eq!(found[0].name, "Wit Studio");
    assert_eq!(found[0].subtitle.as_deref(), Some("Attack on Titan"));
    assert_eq!(found[1].subtitle, None);
    assert!(sent_query(&http, 0).contains("studios(search: $search"));
}

#[tokio::test]
async fn a_blank_query_asks_nothing() {
    let (catalog, http) = catalog_replying(String::new());
    for query in ["", "   "] {
        let found = catalog
            .search_profiles(ProfileKind::Staff, query)
            .await
            .unwrap();
        assert!(found.is_empty());
    }
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn the_query_is_trimmed() {
    let (catalog, http) = catalog_replying(staff_reply());
    catalog
        .search_profiles(ProfileKind::Staff, "  chiwa  ")
        .await
        .unwrap();
    assert_eq!(sent_variables(&http, 0)["search"], "chiwa");
}

#[tokio::test]
async fn an_empty_page_is_an_empty_list() {
    let (catalog, _) = catalog_replying(json!({ "data": { "Page": {} } }).to_string());
    assert!(
        catalog
            .search_profiles(ProfileKind::Studio, "x")
            .await
            .unwrap()
            .is_empty()
    );
}

#[tokio::test]
async fn a_server_error_is_reported() {
    let catalog = catalog_failing_with(HttpResponse::new(503, "down"));
    let result = catalog.search_profiles(ProfileKind::Character, "x").await;
    assert!(matches!(
        result,
        Err(SourceError::Unavailable(_) | SourceError::Network(_))
    ));
}
