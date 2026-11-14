use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::media::ProfileKind;
use infrastructure::catalog::anilist::AniListCatalog;
use infrastructure::clock::SystemClock;
use infrastructure::http::{RateLimitSettings, RateLimitedClient, ReqwestClient, SystemPause};

fn catalog() -> AniListCatalog {
    let transport = Arc::new(ReqwestClient::standard().unwrap());
    let http = RateLimitedClient::new(
        transport,
        Arc::new(SystemPause),
        RateLimitSettings::default(),
    );
    AniListCatalog::new(Arc::new(http), Arc::new(SystemClock))
}

#[tokio::test]
#[ignore = "live network"]
async fn searching_characters_finds_nezuko_with_a_picture_and_a_work() {
    let found = catalog()
        .search_profiles(ProfileKind::Character, "nezuko")
        .await
        .unwrap();
    assert!(!found.is_empty());
    let first = &found[0];
    assert!(first.name.to_lowercase().contains("nezuko"), "{first:?}");
    assert!(first.image_url.is_some());
    assert!(first.subtitle.is_some());
}

#[tokio::test]
#[ignore = "live network"]
async fn searching_staff_finds_a_voice_actor_with_occupations() {
    let found = catalog()
        .search_profiles(ProfileKind::Staff, "saitou chiwa")
        .await
        .unwrap();
    assert!(!found.is_empty());
    assert!(found[0].subtitle.is_some(), "{:?}", found[0]);
}

#[tokio::test]
#[ignore = "live network"]
async fn searching_studios_finds_wit_and_its_profile_lists_works() {
    let catalog = catalog();
    let found = catalog
        .search_profiles(ProfileKind::Studio, "wit studio")
        .await
        .unwrap();
    let wit = found
        .iter()
        .find(|item| item.name == "WIT STUDIO" || item.name.to_lowercase() == "wit studio")
        .unwrap_or_else(|| panic!("no wit studio in {found:?}"));
    let profile = catalog.profile(ProfileKind::Studio, wit.id).await.unwrap();
    assert!(
        profile.appearances.len() >= 5,
        "{}",
        profile.appearances.len()
    );
}
