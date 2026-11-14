use application::ports::MetadataCatalog;
use domain::media::ProfileKind;
use serde_json::json;

use super::catalog_test_support::{catalog_replying, sent_query, sent_variables};

fn studio_reply() -> String {
    let media = |id: u64, title: &str, adult: bool| {
        json!({ "id": id, "type": "ANIME", "title": { "romaji": title }, "isAdult": adult,
                "seasonYear": 2013, "format": "TV",
                "coverImage": { "large": format!("https://img.test/{id}.jpg") } })
    };
    json!({ "data": { "Studio": { "id": 858, "name": "Wit Studio", "media": { "nodes": [
        media(1, "Satu", false), media(2, "Dewasa", true), media(3, "Tiga", false),
    ] } } } })
    .to_string()
}

#[tokio::test]
async fn a_studio_profile_lists_its_visible_works_without_roles() {
    let (catalog, http) = catalog_replying(studio_reply());
    let profile = catalog.profile(ProfileKind::Studio, 858).await.unwrap();
    assert_eq!(profile.name, "Wit Studio");
    assert_eq!(profile.id, 858);
    let titles: Vec<&str> = profile
        .appearances
        .iter()
        .map(|item| item.media.title.romaji.as_str())
        .collect();
    assert_eq!(titles, ["Satu", "Tiga"]);
    assert!(profile.appearances.iter().all(|item| item.role.is_none()));
    assert!(sent_query(&http, 0).contains("Studio(id: $id)"));
    assert_eq!(sent_variables(&http, 0)["id"], 858);
}

fn staff_profile_reply() -> String {
    let media = |id: u64, title: &str, adult: bool| {
        json!({ "id": id, "type": "MANGA", "title": { "romaji": title }, "isAdult": adult,
                "seasonYear": 2012, "format": "MANGA",
                "coverImage": { "large": format!("https://img.test/{id}.jpg") } })
    };
    json!({ "data": { "Staff": {
        "id": 96879, "name": { "full": "Gege Akutami", "native": "芥見下々" },
        "image": null, "description": null,
        "characterMedia": { "edges": [
            { "characterRole": "MAIN", "node": media(1, "Terisi Suara", false),
              "characters": [{ "name": { "full": "Yuji" } }] },
        ] },
        "staffMedia": { "edges": [
            { "staffRole": "Story & Art", "node": media(2, "Jujutsu", false) },
            { "staffRole": "Original Creator", "node": media(1, "Terisi Suara", false) },
            { "staffRole": "", "node": media(3, "Tanpa Peran", false) },
            { "staffRole": "Story", "node": media(4, "Dewasa", true) },
        ] },
    } } })
    .to_string()
}

#[tokio::test]
async fn a_staff_profile_lists_works_they_wrote_with_their_credit() {
    let (catalog, http) = catalog_replying(staff_profile_reply());
    let profile = catalog.profile(ProfileKind::Staff, 96879).await.unwrap();
    let credit = |title: &str| {
        profile
            .appearances
            .iter()
            .find(|item| item.media.title.romaji == title)
            .map(|item| item.credit.clone())
    };
    assert_eq!(credit("Jujutsu"), Some(Some("Story & Art".to_string())));
    assert_eq!(credit("Tanpa Peran"), Some(None));
    assert_eq!(credit("Dewasa"), None);
    assert!(sent_query(&http, 0).contains("staffMedia("));
}

#[tokio::test]
async fn a_work_both_voiced_and_credited_appears_once_with_both() {
    let (catalog, _) = catalog_replying(staff_profile_reply());
    let profile = catalog.profile(ProfileKind::Staff, 96879).await.unwrap();
    let both: Vec<_> = profile
        .appearances
        .iter()
        .filter(|item| item.media.title.romaji == "Terisi Suara")
        .collect();
    assert_eq!(both.len(), 1);
    assert_eq!(both[0].credit.as_deref(), Some("Original Creator"));
    assert_eq!(both[0].characters, vec!["Yuji".to_string()]);
    assert_eq!(profile.appearances.len(), 3);
}
