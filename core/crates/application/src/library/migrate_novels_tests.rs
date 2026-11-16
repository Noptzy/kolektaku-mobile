use std::sync::Arc;

use domain::error::SourceError;
use domain::library::{FavoriteInput, LibraryRepository, ProgressInput};
use domain::media::{MediaFormat, MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId};

use super::migrate_novels::{MIGRATION_FLAG, MigrateNovelEntries, NovelMigration};
use crate::testing::{FakeCatalog, MemoryLibrary};

type Migration = MigrateNovelEntries<MemoryLibrary, FakeCatalog>;

fn id(value: u64) -> MediaId {
    MediaId::new(value).unwrap()
}

fn reference(value: u64) -> MediaRef {
    MediaRef::catalog(id(value))
}

async fn favorite(library: &MemoryLibrary, media: MediaRef, kind: MediaKind) {
    let entry = FavoriteInput {
        media,
        kind,
        title: "title".into(),
        cover_url: None,
    };
    library.toggle_favorite(entry).await.unwrap();
}

async fn read(library: &MemoryLibrary, media: MediaRef, kind: MediaKind) {
    let entry = ProgressInput {
        media,
        kind,
        unit_number: 3.0,
        title: "title".into(),
        cover_url: None,
        position: 1.0,
        length: 10.0,
        updated_at_secs: 5,
    };
    library.save_progress(entry).await.unwrap();
}

async fn rig() -> (Arc<MemoryLibrary>, Migration) {
    let library = Arc::new(MemoryLibrary::new());
    favorite(&library, reference(1), MediaKind::Manga).await;
    favorite(&library, reference(2), MediaKind::Manga).await;
    read(&library, reference(2), MediaKind::Manga).await;
    read(&library, reference(3), MediaKind::Manga).await;
    favorite(&library, reference(9), MediaKind::Anime).await;
    let catalog = Arc::new(
        FakeCatalog::new()
            .with_format(id(1), MediaFormat::Manga)
            .with_format(id(2), MediaFormat::Novel)
            .with_format(id(3), MediaFormat::Novel)
            .with_format(id(9), MediaFormat::Novel),
    );
    let migration = MigrateNovelEntries::new(library.clone(), catalog);
    (library, migration)
}

#[tokio::test]
async fn comics_the_catalog_calls_novels_move_with_their_history() {
    let (library, migration) = rig().await;
    assert_eq!(migration.execute().await, NovelMigration::Moved(3));
    let novels = library.favorites(MediaKind::Novel).await.unwrap();
    assert_eq!(novels.len(), 1);
    assert_eq!(novels[0].entry.media, reference(2));
    assert_eq!(library.history(MediaKind::Novel).await.unwrap().len(), 2);
}

#[tokio::test]
async fn real_comics_and_anime_stay_where_they_are() {
    let (library, migration) = rig().await;
    migration.execute().await;
    let comic = library.is_favorite(MediaKind::Manga, &reference(1)).await;
    assert!(comic.unwrap());
    let anime = library.is_favorite(MediaKind::Anime, &reference(9)).await;
    assert!(anime.unwrap());
}

#[tokio::test]
async fn the_migration_runs_once() {
    let (library, migration) = rig().await;
    migration.execute().await;
    assert_eq!(migration.execute().await, NovelMigration::AlreadyDone);
    let flag = library.preference(MIGRATION_FLAG).await.unwrap();
    assert_eq!(flag.as_deref(), Some("done"));
}

#[tokio::test]
async fn when_the_catalog_does_not_answer_nothing_changes_and_it_is_tried_again_later() {
    let library = Arc::new(MemoryLibrary::new());
    favorite(&library, reference(2), MediaKind::Manga).await;
    let catalog = Arc::new(FakeCatalog::new().with_format(id(2), MediaFormat::Novel));
    catalog.set_failure(Some(SourceError::Network("offline".into())));
    let migration = MigrateNovelEntries::new(library.clone(), catalog.clone());
    assert!(matches!(
        migration.execute().await,
        NovelMigration::Postponed(_)
    ));
    let still = library.is_favorite(MediaKind::Manga, &reference(2)).await;
    assert!(still.unwrap());
    assert!(library.preference(MIGRATION_FLAG).await.unwrap().is_none());
    catalog.set_failure(None);
    assert_eq!(migration.execute().await, NovelMigration::Moved(1));
}

#[tokio::test]
async fn entries_the_catalog_does_not_know_are_left_alone() {
    let library = Arc::new(MemoryLibrary::new());
    favorite(&library, reference(5), MediaKind::Manga).await;
    let migration = MigrateNovelEntries::new(library.clone(), Arc::new(FakeCatalog::new()));
    assert_eq!(migration.execute().await, NovelMigration::Moved(0));
    let still = library.is_favorite(MediaKind::Manga, &reference(5)).await;
    assert!(still.unwrap());
}

#[tokio::test]
async fn entries_that_belong_to_a_site_are_never_guessed_at() {
    let library = Arc::new(MemoryLibrary::new());
    let site = MediaRef::source(SourceId::new("komiku"), ItemId::new("2"));
    favorite(&library, site.clone(), MediaKind::Manga).await;
    let catalog = Arc::new(FakeCatalog::new().with_format(id(2), MediaFormat::Novel));
    let migration = MigrateNovelEntries::new(library.clone(), catalog.clone());
    assert_eq!(migration.execute().await, NovelMigration::Moved(0));
    assert!(library.is_favorite(MediaKind::Manga, &site).await.unwrap());
    assert!(catalog.calls().is_empty());
}

#[tokio::test]
async fn an_empty_library_asks_nothing_and_is_marked_done() {
    let library = Arc::new(MemoryLibrary::new());
    let catalog = Arc::new(FakeCatalog::new());
    let migration = MigrateNovelEntries::new(library.clone(), catalog.clone());
    assert_eq!(migration.execute().await, NovelMigration::Moved(0));
    assert!(catalog.calls().is_empty());
    assert_eq!(migration.execute().await, NovelMigration::AlreadyDone);
}

#[tokio::test]
async fn a_large_library_is_looked_up_in_chunks() {
    let library = Arc::new(MemoryLibrary::new());
    for value in 1..=120 {
        favorite(&library, reference(value), MediaKind::Manga).await;
    }
    let catalog = Arc::new(FakeCatalog::new());
    let migration = MigrateNovelEntries::new(library.clone(), catalog.clone());
    migration.execute().await;
    assert_eq!(
        catalog.calls(),
        vec!["comic_formats 50", "comic_formats 50", "comic_formats 20"]
    );
}
