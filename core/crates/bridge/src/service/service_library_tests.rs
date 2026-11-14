use super::service_support::{Folder, catalog_ref, state};
use super::{browse, detail, library, sources};
use crate::dto::library::{FavoriteDto, ProgressDto, UnitOrderDto};
use crate::dto::media::MediaKindDto;

#[tokio::test]
async fn library_functions_round_trip_through_the_dtos() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let favorite = FavoriteDto {
        reference: catalog_ref(),
        kind: MediaKindDto::Anime,
        title: "Spy x Family".into(),
        cover_url: None,
        added_at_secs: 0,
    };
    assert!(library::toggle_favorite(&state, favorite).await.unwrap());
    assert!(
        library::is_favorite(&state, MediaKindDto::Anime, &catalog_ref())
            .await
            .unwrap()
    );
    assert_eq!(
        library::favorites(&state, MediaKindDto::Anime)
            .await
            .unwrap()
            .len(),
        1
    );
    let progress = ProgressDto {
        reference: catalog_ref(),
        kind: MediaKindDto::Anime,
        unit_number: 2.0,
        title: "Spy x Family".into(),
        cover_url: None,
        position: 100.0,
        length: 1440.0,
        updated_at_secs: 5,
        completed: false,
    };
    library::save_progress(&state, progress).await.unwrap();
    assert_eq!(
        library::continue_list(&state, MediaKindDto::Anime)
            .await
            .unwrap()
            .len(),
        1
    );
    assert!(
        library::last_progress(&state, MediaKindDto::Anime, &catalog_ref())
            .await
            .unwrap()
            .is_some()
    );
    library::set_unit_order(
        &state,
        MediaKindDto::Anime,
        &catalog_ref(),
        UnitOrderDto::Desc,
    )
    .await
    .unwrap();
    assert_eq!(
        library::unit_order(&state, MediaKindDto::Anime, &catalog_ref())
            .await
            .unwrap(),
        UnitOrderDto::Desc
    );
    library::add_search(&state, MediaKindDto::Anime, "spy")
        .await
        .unwrap();
    assert_eq!(
        library::searches(&state, MediaKindDto::Anime)
            .await
            .unwrap(),
        vec!["spy"]
    );
}

#[tokio::test]
async fn switching_a_site_off_removes_it_from_every_flow() {
    let folder = Folder::new();
    let state = state(&folder).await;
    assert!(sources::status(&state)[0].enabled);
    sources::set_enabled(&state, "a", false).await;
    assert!(!sources::status(&state)[0].enabled);
    let page = browse::search(&state, MediaKindDto::Anime, "spy x family", 1)
        .await
        .unwrap();
    assert!(page.cards[0].sources.is_empty());
    let restarted = self::state(&folder).await;
    assert!(!sources::status(&restarted)[0].enabled);
}

#[tokio::test]
async fn candidates_for_a_manual_correction_come_from_the_chosen_site() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let found = browse::source_candidates(&state, "a", "spy x family")
        .await
        .unwrap();
    assert_eq!(found[0].item, "a-spy");
    let chosen = detail::select_source(&state, MediaKindDto::Anime, &catalog_ref(), "a", "a-spy")
        .await
        .unwrap();
    assert!(chosen[0].manual);
    detail::forget_match(&state, MediaKindDto::Anime, &catalog_ref())
        .await
        .unwrap();
}
