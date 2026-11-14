use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{CharacterRole, ProfileKind};
use serde_json::{Value, json};

use super::catalog_test_support::{
    catalog_failing_with, catalog_replying, sent_query, sent_variables,
};
use crate::http::HttpResponse;

fn media(id: u64, title: &str, year: u16, adult: bool) -> Value {
    json!({
        "id": id,
        "type": "ANIME",
        "title": { "romaji": title },
        "seasonYear": year,
        "startDate": { "year": year },
        "format": "TV",
        "isAdult": adult,
        "coverImage": { "large": format!("https://img.test/{id}.jpg") },
    })
}

fn character_reply() -> String {
    json!({ "data": { "Character": {
        "id": 127518,
        "name": { "full": "Nezuko Kamado", "native": "竈門禰豆子" },
        "image": { "large": "https://img.test/nezuko.png" },
        "description": "<p><strong>Tinggi:</strong> 153 cm</p>~!bocoran!~",
        "media": { "edges": [
            { "characterRole": "SUPPORTING", "node": media(3, "Film", 2025, false) },
            { "characterRole": "MAIN", "node": media(2, "Musim", 2023, false) },
            { "characterRole": "MAIN", "node": media(9, "Dewasa", 2020, true) },
        ] },
    } } })
    .to_string()
}

fn staff_reply() -> String {
    json!({ "data": { "Staff": {
        "id": 95061,
        "name": { "full": "Chiwa Saitou", "native": "" },
        "image": null,
        "description": null,
        "characterMedia": { "edges": [
            { "characterRole": "MAIN", "node": media(5, "Satu", 2012, false),
              "characters": [{ "name": { "full": "Mayoi" } }] },
            { "characterRole": "SUPPORTING", "node": media(5, "Satu", 2012, false),
              "characters": [{ "name": { "full": "Mayoi" } }, { "name": { "full": "Nadeko" } }] },
            { "characterRole": "MAIN", "node": media(6, "Dua", 2009, false),
              "characters": [{ "name": null }] },
        ] },
    } } })
    .to_string()
}

#[tokio::test]
async fn a_character_has_a_name_a_picture_and_its_titles() {
    let (catalog, http) = catalog_replying(character_reply());
    let profile = catalog
        .profile(ProfileKind::Character, 127518)
        .await
        .unwrap();
    assert_eq!(profile.id, 127518);
    assert_eq!(profile.name, "Nezuko Kamado");
    assert_eq!(profile.native_name.as_deref(), Some("竈門禰豆子"));
    assert_eq!(
        profile.image_url.as_deref(),
        Some("https://img.test/nezuko.png")
    );
    assert_eq!(sent_variables(&http, 0)["id"], 127518);
    assert!(sent_query(&http, 0).contains("Character(id: $id)"));
    let titles: Vec<&str> = profile
        .appearances
        .iter()
        .map(|item| item.media.title.romaji.as_str())
        .collect();
    assert_eq!(titles, vec!["Film", "Musim"]);
    assert_eq!(profile.appearances[0].role, Some(CharacterRole::Supporting));
    assert_eq!(profile.appearances[1].media.year, Some(2023));
}

#[tokio::test]
async fn the_description_is_cleaned_and_spoilers_are_dropped() {
    let (catalog, _) = catalog_replying(character_reply());
    let profile = catalog.profile(ProfileKind::Character, 1).await.unwrap();
    assert!(profile.description.contains("<b>Tinggi:</b>"));
    assert!(!profile.description.contains("bocoran"));
}

#[tokio::test]
async fn adult_titles_never_appear_on_a_profile() {
    let (catalog, _) = catalog_replying(character_reply());
    let profile = catalog.profile(ProfileKind::Character, 1).await.unwrap();
    assert!(profile.appearances.iter().all(|item| !item.media.is_adult));
    assert!(
        profile
            .appearances
            .iter()
            .all(|item| item.media.id.get() != 9)
    );
}

#[tokio::test]
async fn a_voice_actor_lists_each_title_once_with_every_character() {
    let (catalog, http) = catalog_replying(staff_reply());
    let profile = catalog.profile(ProfileKind::Staff, 95061).await.unwrap();
    assert!(sent_query(&http, 0).contains("Staff(id: $id)"));
    assert_eq!(profile.appearances.len(), 2);
    let first = &profile.appearances[0];
    assert_eq!(first.media.title.romaji, "Satu");
    assert_eq!(first.characters, vec!["Mayoi", "Nadeko"]);
    assert_eq!(first.role, Some(CharacterRole::Main));
    assert!(profile.appearances[1].characters.is_empty());
}

#[tokio::test]
async fn missing_pictures_native_names_and_descriptions_are_fine() {
    let (catalog, _) = catalog_replying(staff_reply());
    let profile = catalog.profile(ProfileKind::Staff, 95061).await.unwrap();
    assert_eq!(profile.name, "Chiwa Saitou");
    assert!(profile.native_name.is_none());
    assert!(profile.image_url.is_none());
    assert!(profile.description.is_empty());
}

#[tokio::test]
async fn a_profile_without_titles_is_still_a_profile() {
    let body = json!({ "data": { "Character": { "id": 1, "name": { "full": "X" } } } });
    let (catalog, _) = catalog_replying(body.to_string());
    let profile = catalog.profile(ProfileKind::Character, 1).await.unwrap();
    assert!(profile.appearances.is_empty());
}

#[tokio::test]
async fn an_unknown_id_is_not_found() {
    let body = r#"{"errors":[{"message":"Not Found.","status":404}],"data":{"Character":null}}"#;
    let catalog = catalog_failing_with(HttpResponse::new(404, body));
    let error = catalog
        .profile(ProfileKind::Character, 1)
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::NotFound("Not Found.".into()));
}

#[tokio::test]
async fn an_unreadable_answer_is_a_markup_change() {
    let body = json!({ "data": { "Character": { "id": "x" } } });
    let (catalog, _) = catalog_replying(body.to_string());
    let error = catalog
        .profile(ProfileKind::Character, 1)
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}
