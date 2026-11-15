use std::sync::Arc;

use application::testing::FakeClock;
use domain::library::{FavoriteInput, LibraryRepository, ProgressInput, UnitOrder};
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId};

use super::JsonLibraryRepository;
use crate::storage::temp_folder::TempFolder;

pub(super) fn media(id: u64) -> MediaRef {
    MediaRef::catalog(MediaId::new(id).unwrap())
}

pub(super) fn repository(folder: &TempFolder) -> JsonLibraryRepository {
    JsonLibraryRepository::new(folder.file("library.json"), Arc::new(FakeClock::at(500)))
}

pub(super) fn favorite(reference: MediaRef, kind: MediaKind) -> FavoriteInput {
    FavoriteInput {
        media: reference,
        kind,
        title: "title".into(),
        cover_url: None,
    }
}

pub(super) fn progress(reference: MediaRef, kind: MediaKind, unit: f64) -> ProgressInput {
    ProgressInput {
        media: reference,
        kind,
        unit_number: unit,
        title: "title".into(),
        cover_url: None,
        position: 3.0,
        length: 10.0,
        updated_at_secs: 20,
    }
}

pub(super) async fn filled(library: &JsonLibraryRepository) {
    for (reference, kind) in [
        (media(1), MediaKind::Anime),
        (media(2), MediaKind::Manga),
        (media(3), MediaKind::Manga),
    ] {
        library
            .toggle_favorite(favorite(reference, kind))
            .await
            .unwrap();
    }
    library
        .save_progress(progress(media(2), MediaKind::Manga, 4.0))
        .await
        .unwrap();
    library
        .save_progress(progress(media(3), MediaKind::Manga, 9.0))
        .await
        .unwrap();
    library
        .set_unit_order(MediaKind::Manga, &media(2), UnitOrder::Desc)
        .await
        .unwrap();
}

#[tokio::test]
async fn the_chosen_comics_move_with_their_history_and_order() {
    let folder = TempFolder::new("move-chosen");
    let library = repository(&folder);
    filled(&library).await;
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await
        .unwrap();
    assert_eq!(moved, 3);
    assert!(
        library
            .is_favorite(MediaKind::Novel, &media(2))
            .await
            .unwrap()
    );
    assert!(
        !library
            .is_favorite(MediaKind::Manga, &media(2))
            .await
            .unwrap()
    );
    assert_eq!(library.history(MediaKind::Novel).await.unwrap().len(), 1);
    assert_eq!(
        library
            .unit_order(MediaKind::Novel, &media(2))
            .await
            .unwrap(),
        UnitOrder::Desc
    );
    assert_eq!(
        library
            .unit_order(MediaKind::Manga, &media(2))
            .await
            .unwrap(),
        UnitOrder::default()
    );
}

#[tokio::test]
async fn everything_else_stays_where_it_was() {
    let folder = TempFolder::new("move-rest");
    let library = repository(&folder);
    filled(&library).await;
    library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await
        .unwrap();
    assert!(
        library
            .is_favorite(MediaKind::Anime, &media(1))
            .await
            .unwrap()
    );
    assert!(
        library
            .is_favorite(MediaKind::Manga, &media(3))
            .await
            .unwrap()
    );
    let comics = library.history(MediaKind::Manga).await.unwrap();
    assert_eq!(comics.len(), 1);
    assert_eq!(comics[0].entry.media, media(3));
}

#[tokio::test]
async fn an_anime_with_the_same_id_is_never_moved() {
    let folder = TempFolder::new("move-anime");
    let library = repository(&folder);
    library
        .toggle_favorite(favorite(media(5), MediaKind::Anime))
        .await
        .unwrap();
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(5)])
        .await
        .unwrap();
    assert_eq!(moved, 0);
    assert!(
        library
            .is_favorite(MediaKind::Anime, &media(5))
            .await
            .unwrap()
    );
}

#[tokio::test]
async fn an_entry_that_belongs_to_a_site_is_not_touched_by_a_catalog_id() {
    let folder = TempFolder::new("move-site");
    let library = repository(&folder);
    let site = MediaRef::source(SourceId::new("komiku"), ItemId::new("2"));
    library
        .toggle_favorite(favorite(site.clone(), MediaKind::Manga))
        .await
        .unwrap();
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await
        .unwrap();
    assert_eq!(moved, 0);
    assert!(library.is_favorite(MediaKind::Manga, &site).await.unwrap());
}
