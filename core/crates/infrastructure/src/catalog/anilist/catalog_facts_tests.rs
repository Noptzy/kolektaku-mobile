use application::ports::MetadataCatalog;
use domain::media::{FactKind, LinkKind, ProfileKind};
use serde_json::json;

use super::catalog_test_support::catalog_replying;

fn fact(facts: &[domain::media::ProfileFact], kind: FactKind) -> Option<&str> {
    facts
        .iter()
        .find(|item| item.kind == kind)
        .map(|item| item.value.as_str())
}

fn staff_reply() -> String {
    json!({ "data": { "Staff": {
        "id": 96879, "name": { "full": "Chiwa Saitou", "native": "斎藤千和" },
        "image": null,
        "description": "Bio. <a href=\"https://twitter.com/chiwa\">Twitter</a> <a href='https://www.instagram.com/chiwa'>IG</a> ~!<a href=\"https://spoiler.test\">x</a>!~",
        "primaryOccupations": ["Voice Actor", "Singer"],
        "gender": "Female",
        "dateOfBirth": { "year": 1980, "month": 6, "day": 12 },
        "dateOfDeath": { "year": null, "month": null, "day": null },
        "age": 46,
        "yearsActive": [2001],
        "homeTown": "Tokyo",
        "bloodType": "A",
        "languageV2": "Japanese",
        "favourites": 4021,
        "siteUrl": "https://anilist.co/staff/96879",
        "characterMedia": { "edges": [] },
        "staffMedia": { "edges": [] },
    } } })
    .to_string()
}

fn character_reply() -> String {
    json!({ "data": { "Character": {
        "id": 127518,
        "name": { "full": "Nezuko Kamado", "native": "竈門禰豆子", "alternative": ["Nezu-chan", "Nezuko Kamado", ""] },
        "image": null, "description": "",
        "gender": "Female",
        "dateOfBirth": { "year": null, "month": 12, "day": 28 },
        "age": "14-15", "bloodType": "O", "favourites": 0,
        "siteUrl": "https://anilist.co/character/127518",
        "media": { "edges": [] },
    } } })
    .to_string()
}

#[tokio::test]
async fn a_staff_profile_carries_its_biography_facts() {
    let (catalog, _) = catalog_replying(staff_reply());
    let profile = catalog.profile(ProfileKind::Staff, 96879).await.unwrap();
    let facts = &profile.facts;
    assert_eq!(
        fact(facts, FactKind::Occupations),
        Some("Voice Actor, Singer")
    );
    assert_eq!(fact(facts, FactKind::Birthday), Some("1980-06-12"));
    assert_eq!(fact(facts, FactKind::Age), Some("46"));
    assert_eq!(fact(facts, FactKind::Gender), Some("Female"));
    assert_eq!(fact(facts, FactKind::BloodType), Some("A"));
    assert_eq!(fact(facts, FactKind::HomeTown), Some("Tokyo"));
    assert_eq!(fact(facts, FactKind::YearsActive), Some("2001-"));
    assert_eq!(fact(facts, FactKind::Language), Some("Japanese"));
    assert_eq!(fact(facts, FactKind::Favourites), Some("4021"));
    assert_eq!(fact(facts, FactKind::Died), None);
}

#[tokio::test]
async fn a_staff_profile_links_social_pages_from_its_description() {
    let (catalog, _) = catalog_replying(staff_reply());
    let profile = catalog.profile(ProfileKind::Staff, 96879).await.unwrap();
    let sites: Vec<&str> = profile
        .links
        .iter()
        .map(|link| link.site.as_str())
        .collect();
    assert_eq!(sites, ["Twitter", "Instagram", "AniList"]);
    assert_eq!(profile.links[0].kind, LinkKind::Social);
    assert_eq!(profile.links[0].url, "https://twitter.com/chiwa");
    assert!(
        profile
            .links
            .iter()
            .all(|link| !link.url.contains("spoiler"))
    );
}

#[tokio::test]
async fn a_character_has_partial_birthday_age_text_and_nicknames() {
    let (catalog, _) = catalog_replying(character_reply());
    let profile = catalog
        .profile(ProfileKind::Character, 127518)
        .await
        .unwrap();
    let facts = &profile.facts;
    assert_eq!(fact(facts, FactKind::Birthday), Some("--12-28"));
    assert_eq!(fact(facts, FactKind::Age), Some("14-15"));
    assert_eq!(fact(facts, FactKind::Nicknames), Some("Nezu-chan"));
    assert_eq!(fact(facts, FactKind::Favourites), None);
    assert_eq!(profile.links.len(), 1);
    assert_eq!(profile.links[0].site, "AniList");
}

#[tokio::test]
async fn a_profile_with_nothing_extra_has_no_facts_and_no_links() {
    let reply = json!({ "data": { "Character": {
        "id": 1, "name": { "full": "A" }, "media": { "edges": [] },
    } } })
    .to_string();
    let (catalog, _) = catalog_replying(reply);
    let profile = catalog.profile(ProfileKind::Character, 1).await.unwrap();
    assert!(profile.facts.is_empty());
    assert!(profile.links.is_empty());
}

#[tokio::test]
async fn a_studio_shows_its_kind_popularity_and_catalog_page() {
    let reply = json!({ "data": { "Studio": {
        "id": 858, "name": "Wit Studio", "favourites": 1234,
        "isAnimationStudio": true, "siteUrl": "https://anilist.co/studio/858",
        "media": { "nodes": [] },
    } } })
    .to_string();
    let (catalog, _) = catalog_replying(reply);
    let profile = catalog.profile(ProfileKind::Studio, 858).await.unwrap();
    assert_eq!(
        fact(&profile.facts, FactKind::StudioType),
        Some("animation")
    );
    assert_eq!(fact(&profile.facts, FactKind::Favourites), Some("1234"));
    assert_eq!(profile.links[0].url, "https://anilist.co/studio/858");
}

#[tokio::test]
async fn a_producer_that_is_not_an_animation_studio_says_so() {
    let reply = json!({ "data": { "Studio": {
        "id": 2, "name": "Penerbit", "isAnimationStudio": false, "media": { "nodes": [] },
    } } })
    .to_string();
    let (catalog, _) = catalog_replying(reply);
    let profile = catalog.profile(ProfileKind::Studio, 2).await.unwrap();
    assert_eq!(fact(&profile.facts, FactKind::StudioType), Some("producer"));
    assert!(profile.links.is_empty());
}
