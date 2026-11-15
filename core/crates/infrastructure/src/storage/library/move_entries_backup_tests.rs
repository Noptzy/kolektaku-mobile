use domain::library::LibraryRepository;
use domain::media::MediaKind;

use super::move_entries_tests::{filled, media, repository};
use crate::storage::temp_folder::TempFolder;

const BACKUP: &str = "library.json.before-novel";

#[tokio::test]
async fn the_old_file_is_kept_before_anything_changes() {
    let folder = TempFolder::new("move-backup");
    let library = repository(&folder);
    filled(&library).await;
    let before = std::fs::read_to_string(folder.file("library.json")).unwrap();
    library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await
        .unwrap();
    assert_eq!(
        std::fs::read_to_string(folder.file(BACKUP)).unwrap(),
        before
    );
}

#[tokio::test]
async fn the_first_copy_is_never_replaced_by_a_later_one() {
    let folder = TempFolder::new("move-backup-once");
    let library = repository(&folder);
    filled(&library).await;
    let before = std::fs::read_to_string(folder.file("library.json")).unwrap();
    library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await
        .unwrap();
    library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(3)])
        .await
        .unwrap();
    assert_eq!(
        std::fs::read_to_string(folder.file(BACKUP)).unwrap(),
        before
    );
}

#[tokio::test]
async fn nothing_to_move_changes_and_copies_nothing() {
    let folder = TempFolder::new("move-nothing");
    let library = repository(&folder);
    filled(&library).await;
    let before = std::fs::read_to_string(folder.file("library.json")).unwrap();
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(99)])
        .await
        .unwrap();
    assert_eq!(moved, 0);
    assert_eq!(
        std::fs::read_to_string(folder.file("library.json")).unwrap(),
        before
    );
    assert!(!folder.file(BACKUP).exists());
}

#[tokio::test]
async fn an_empty_library_has_nothing_to_move_and_no_file_appears() {
    let folder = TempFolder::new("move-empty");
    let library = repository(&folder);
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await
        .unwrap();
    assert_eq!(moved, 0);
    assert!(!folder.file("library.json").exists());
}

#[tokio::test]
async fn a_failed_copy_leaves_the_library_exactly_as_it_was() {
    let folder = TempFolder::new("move-copy-fails");
    let library = repository(&folder);
    filled(&library).await;
    std::fs::create_dir(folder.file(BACKUP)).unwrap();
    let before = std::fs::read_to_string(folder.file("library.json")).unwrap();
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(2)])
        .await;
    assert!(moved.is_err());
    assert_eq!(
        std::fs::read_to_string(folder.file("library.json")).unwrap(),
        before
    );
    assert!(
        library
            .is_favorite(MediaKind::Manga, &media(2))
            .await
            .unwrap()
    );
}
