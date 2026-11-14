use super::people;
use super::service_support::{Folder, state};
use crate::dto::profile::ProfileKindDto;

#[tokio::test]
async fn a_character_search_returns_the_dtos_of_the_hits() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let found = people::search(&state, ProfileKindDto::Character, "nezuko")
        .await
        .unwrap();
    assert_eq!(found.len(), 1);
    assert_eq!(found[0].id, 127518);
    assert_eq!(found[0].kind, ProfileKindDto::Character);
    assert_eq!(found[0].subtitle.as_deref(), Some("Demon Slayer"));
}

#[tokio::test]
async fn each_kind_searches_its_own_list() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let studios = people::search(&state, ProfileKindDto::Studio, "wit")
        .await
        .unwrap();
    assert_eq!(studios[0].name, "Wit Studio");
    let none = people::search(&state, ProfileKindDto::Staff, "nezuko")
        .await
        .unwrap();
    assert!(none.is_empty());
}

#[tokio::test]
async fn a_failing_catalog_is_reported_as_a_bridge_error() {
    let folder = Folder::new();
    let state = state(&folder).await;
    state
        .catalog
        .set_failure(Some(domain::error::SourceError::Network("down".into())));
    let result = people::search(&state, ProfileKindDto::Studio, "wit").await;
    assert_eq!(
        result.unwrap_err().kind,
        crate::error::BridgeErrorKind::Network
    );
}
