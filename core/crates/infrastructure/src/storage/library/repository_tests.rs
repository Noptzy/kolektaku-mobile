use std::sync::Arc;

use application::testing::FakeClock;
use domain::library::{FavoriteInput, LibraryRepository, ProgressInput, UnitOrder};
use domain::media::{MediaId, MediaKind, MediaRef};

use super::JsonLibraryRepository;
use crate::storage::temp_folder::TempFolder;

fn media(id: u64) -> MediaRef {
    MediaRef::catalog(MediaId::new(id).unwrap())
}

fn repository(folder: &TempFolder) -> JsonLibraryRepository {
    JsonLibraryRepository::new(folder.file("library.json"), Arc::new(FakeClock::at(500)))
}

fn progress(unit: f64, at: u64) -> ProgressInput {
    ProgressInput {
        media: media(1),
        kind: MediaKind::Anime,
        unit_number: unit,
        title: "Sousou no Frieren".into(),
        cover_url: None,
        position: 60.0,
        length: 1440.0,
        updated_at_secs: at,
    }
}

fn favorite(id: u64) -> FavoriteInput {
    FavoriteInput {
        media: media(id),
        kind: MediaKind::Anime,
        title: format!("title {id}"),
        cover_url: None,
    }
}

#[tokio::test]
async fn favorites_progress_order_preferences_and_searches_survive_a_restart() {
    let folder = TempFolder::new("library-restart");
    {
        let library = repository(&folder);
        assert!(library.toggle_favorite(favorite(1)).await.unwrap());
        library.save_progress(progress(2.0, 10)).await.unwrap();
        library
            .set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Desc)
            .await
            .unwrap();
        library.set_preference("lastMenu", "manga").await.unwrap();
        library
            .add_search(MediaKind::Anime, "frieren")
            .await
            .unwrap();
    }
    let library = repository(&folder);
    assert_eq!(
        library.favorites(MediaKind::Anime).await.unwrap()[0].added_at_secs,
        500
    );
    assert!(
        library
            .is_favorite(MediaKind::Anime, &media(1))
            .await
            .unwrap()
    );
    assert_eq!(
        library
            .last_progress(MediaKind::Anime, &media(1))
            .await
            .unwrap()
            .unwrap()
            .entry
            .unit_number,
        2.0
    );
    assert_eq!(
        library
            .unit_order(MediaKind::Anime, &media(1))
            .await
            .unwrap(),
        UnitOrder::Desc
    );
    assert_eq!(
        library.preference("lastMenu").await.unwrap().as_deref(),
        Some("manga")
    );
    assert_eq!(
        library.searches(MediaKind::Anime).await.unwrap(),
        vec!["frieren"]
    );
}

#[tokio::test]
async fn overlapping_saves_do_not_lose_writes() {
    let folder = TempFolder::new("library-overlap");
    let library = Arc::new(repository(&folder));
    let mut tasks = tokio::task::JoinSet::new();
    for unit in 1..=10_u32 {
        let library = Arc::clone(&library);
        tasks.spawn(async move {
            library
                .save_progress(progress(f64::from(unit), u64::from(unit)))
                .await
        });
    }
    for id in 1..=5 {
        let library = Arc::clone(&library);
        tasks.spawn(async move { library.toggle_favorite(favorite(id)).await.map(|_| ()) });
    }
    while let Some(done) = tasks.join_next().await {
        done.unwrap().unwrap();
    }
    assert_eq!(library.history(MediaKind::Anime).await.unwrap().len(), 10);
    assert_eq!(library.favorites(MediaKind::Anime).await.unwrap().len(), 5);
}

#[tokio::test]
async fn a_corrupt_file_never_stops_the_app_from_starting() {
    let folder = TempFolder::new("library-corrupt");
    std::fs::write(folder.file("library.json"), "{not json").unwrap();
    let library = repository(&folder);
    assert!(
        library
            .favorites(MediaKind::Anime)
            .await
            .unwrap()
            .is_empty()
    );
    assert!(library.history(MediaKind::Anime).await.unwrap().is_empty());
    assert!(library.toggle_favorite(favorite(1)).await.unwrap());
    assert!(folder.file("library.json.corrupt").exists());
}

#[tokio::test]
async fn one_bad_section_does_not_erase_the_others() {
    let folder = TempFolder::new("library-partial");
    let good = serde_json::to_string(&serde_json::json!({
        "version": 1,
        "history": [{"nonsense": true}],
        "preferences": {"lastMenu": "manga"}
    }))
    .unwrap();
    std::fs::write(folder.file("library.json"), good).unwrap();
    let library = repository(&folder);
    assert!(library.history(MediaKind::Anime).await.unwrap().is_empty());
    assert_eq!(
        library.preference("lastMenu").await.unwrap().as_deref(),
        Some("manga")
    );
}

#[tokio::test]
async fn removing_and_clearing_history_are_stored() {
    let folder = TempFolder::new("library-remove");
    let library = repository(&folder);
    library.save_progress(progress(1.0, 1)).await.unwrap();
    library.save_progress(progress(2.0, 2)).await.unwrap();
    library
        .remove_progress(MediaKind::Anime, &media(1), 1.0)
        .await
        .unwrap();
    assert_eq!(library.history(MediaKind::Anime).await.unwrap().len(), 1);
    library.clear_history(MediaKind::Anime).await.unwrap();
    assert!(
        repository(&folder)
            .history(MediaKind::Anime)
            .await
            .unwrap()
            .is_empty()
    );
    library.add_search(MediaKind::Anime, "x").await.unwrap();
    library.clear_searches(MediaKind::Anime).await.unwrap();
    assert!(library.searches(MediaKind::Anime).await.unwrap().is_empty());
}

#[tokio::test]
async fn a_write_that_cannot_happen_is_reported() {
    let folder = TempFolder::new("library-unwritable");
    std::fs::write(folder.file("blocker"), "file").unwrap();
    let library = JsonLibraryRepository::new(
        folder.file("blocker").join("library.json"),
        Arc::new(FakeClock::at(1)),
    );
    assert!(library.toggle_favorite(favorite(1)).await.is_err());
}
