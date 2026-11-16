use std::sync::Arc;

use application::testing::FakeClock;
use domain::library::{FavoriteInput, LibraryRepository, ProgressInput, UnitOrder};
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId};

use super::{Database, SqliteLibraryRepository};
use crate::storage::TempFolder;

pub(super) fn media(id: u64) -> MediaRef {
    MediaRef::catalog(MediaId::new(id).unwrap())
}

pub(super) fn memory() -> SqliteLibraryRepository {
    SqliteLibraryRepository::new(Database::in_memory().unwrap(), Arc::new(FakeClock::at(500)))
}

pub(super) fn progress(id: u64, unit: f64, position: f64, at: u64) -> ProgressInput {
    ProgressInput {
        media: media(id),
        kind: MediaKind::Anime,
        unit_number: unit,
        title: "Sousou no Frieren".into(),
        cover_url: None,
        position,
        length: 1440.0,
        updated_at_secs: at,
    }
}

pub(super) fn favorite(id: u64, kind: MediaKind) -> FavoriteInput {
    FavoriteInput {
        media: media(id),
        kind,
        title: format!("title {id}"),
        cover_url: None,
    }
}

#[tokio::test]
async fn everything_survives_a_restart() {
    let folder = TempFolder::new("sqlite-restart");
    let path = folder.file("kolektaku.db");
    {
        let library = SqliteLibraryRepository::open(&path, Arc::new(FakeClock::at(500))).unwrap();
        assert!(
            library
                .toggle_favorite(favorite(1, MediaKind::Anime))
                .await
                .unwrap()
        );
        library
            .save_progress(progress(1, 2.0, 60.0, 10))
            .await
            .unwrap();
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
    let library = SqliteLibraryRepository::open(&path, Arc::new(FakeClock::at(900))).unwrap();
    let saved = library.favorites(MediaKind::Anime).await.unwrap();
    assert_eq!(saved[0].added_at_secs, 500);
    assert!(
        library
            .is_favorite(MediaKind::Anime, &media(1))
            .await
            .unwrap()
    );
    let last = library
        .last_progress(MediaKind::Anime, &media(1))
        .await
        .unwrap();
    assert_eq!(last.unwrap().entry.unit_number, 2.0);
    let order = library
        .unit_order(MediaKind::Anime, &media(1))
        .await
        .unwrap();
    assert_eq!(order, UnitOrder::Desc);
    let menu = library.preference("lastMenu").await.unwrap();
    assert_eq!(menu.as_deref(), Some("manga"));
    assert_eq!(
        library.searches(MediaKind::Anime).await.unwrap(),
        vec!["frieren"]
    );
}

#[tokio::test]
async fn toggling_adds_then_removes_and_keeps_the_newest_first() {
    let library = memory();
    assert!(
        library
            .toggle_favorite(favorite(1, MediaKind::Anime))
            .await
            .unwrap()
    );
    assert!(
        library
            .toggle_favorite(favorite(2, MediaKind::Anime))
            .await
            .unwrap()
    );
    let titles: Vec<String> = library
        .favorites(MediaKind::Anime)
        .await
        .unwrap()
        .into_iter()
        .map(|item| item.entry.title)
        .collect();
    assert_eq!(titles, vec!["title 2", "title 1"]);
    assert!(
        !library
            .toggle_favorite(favorite(1, MediaKind::Anime))
            .await
            .unwrap()
    );
    assert!(
        !library
            .is_favorite(MediaKind::Anime, &media(1))
            .await
            .unwrap()
    );
}

#[tokio::test]
async fn the_same_id_as_two_kinds_stays_apart_and_site_titles_work() {
    let library = memory();
    library
        .toggle_favorite(favorite(1, MediaKind::Anime))
        .await
        .unwrap();
    library
        .toggle_favorite(favorite(1, MediaKind::Manga))
        .await
        .unwrap();
    assert_eq!(library.favorites(MediaKind::Anime).await.unwrap().len(), 1);
    assert_eq!(library.favorites(MediaKind::Manga).await.unwrap().len(), 1);
    let site = MediaRef::source(SourceId::new("komiku"), ItemId::new("one-piece"));
    let input = FavoriteInput {
        media: site.clone(),
        kind: MediaKind::Manga,
        title: "One Piece".into(),
        cover_url: None,
    };
    assert!(library.toggle_favorite(input).await.unwrap());
    assert!(library.is_favorite(MediaKind::Manga, &site).await.unwrap());
}

#[tokio::test]
async fn one_entry_per_unit_newest_first_with_finished_units_marked() {
    let library = memory();
    library
        .save_progress(progress(1, 1.0, 1300.0, 10))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 2.0, 100.0, 11))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 2.0, 200.0, 12))
        .await
        .unwrap();
    let history = library.history(MediaKind::Anime).await.unwrap();
    let shape: Vec<(f64, f64, bool)> = history
        .iter()
        .map(|item| (item.entry.unit_number, item.entry.position, item.completed))
        .collect();
    assert_eq!(shape, vec![(2.0, 200.0, false), (1.0, 1300.0, true)]);
    let found = library
        .progress_for(MediaKind::Anime, &media(1), 1.0)
        .await
        .unwrap();
    assert!(found.unwrap().completed);
    let last = library
        .last_progress(MediaKind::Anime, &media(1))
        .await
        .unwrap();
    assert_eq!(last.unwrap().entry.unit_number, 2.0);
}

#[tokio::test]
async fn a_negative_position_is_not_stored() {
    let library = memory();
    library
        .save_progress(progress(1, 1.0, -5.0, 10))
        .await
        .unwrap();
    assert!(library.history(MediaKind::Anime).await.unwrap().is_empty());
}

#[tokio::test]
async fn removing_and_clearing_work_per_kind() {
    let library = memory();
    library
        .save_progress(progress(1, 1.0, 10.0, 10))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 2.0, 10.0, 11))
        .await
        .unwrap();
    library
        .remove_progress(MediaKind::Anime, &media(1), 1.0)
        .await
        .unwrap();
    assert_eq!(library.history(MediaKind::Anime).await.unwrap().len(), 1);
    library.clear_history(MediaKind::Anime).await.unwrap();
    assert!(library.history(MediaKind::Anime).await.unwrap().is_empty());
}
