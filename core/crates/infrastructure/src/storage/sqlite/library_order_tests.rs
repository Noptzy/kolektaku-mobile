use domain::library::{LibraryRepository, UnitOrder};
use domain::media::MediaKind;

use super::library_tests::{favorite, media, memory, progress};

#[tokio::test]
async fn the_unit_order_defaults_and_forgets_the_default() {
    let library = memory();
    let default = library
        .unit_order(MediaKind::Anime, &media(1))
        .await
        .unwrap();
    assert_eq!(default, UnitOrder::Asc);
    library
        .set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Desc)
        .await
        .unwrap();
    let other = library
        .unit_order(MediaKind::Manga, &media(1))
        .await
        .unwrap();
    assert_eq!(other, UnitOrder::Asc);
    library
        .set_unit_order(MediaKind::Anime, &media(1), UnitOrder::Asc)
        .await
        .unwrap();
    let back = library
        .unit_order(MediaKind::Anime, &media(1))
        .await
        .unwrap();
    assert_eq!(back, UnitOrder::Asc);
}

#[tokio::test]
async fn preferences_are_replaced_not_duplicated() {
    let library = memory();
    assert_eq!(library.preference("a").await.unwrap(), None);
    library.set_preference("a", "1").await.unwrap();
    library.set_preference("a", "2").await.unwrap();
    assert_eq!(library.preference("a").await.unwrap().as_deref(), Some("2"));
}

#[tokio::test]
async fn the_last_eight_searches_are_kept_newest_first_without_duplicates() {
    let library = memory();
    for query in ["a", "b", "c", "d", "e", "f", "g", "h", "i", "B "] {
        library.add_search(MediaKind::Anime, query).await.unwrap();
    }
    let found = library.searches(MediaKind::Anime).await.unwrap();
    assert_eq!(found.len(), 8);
    assert_eq!(found[0], "B");
    assert_eq!(
        found
            .iter()
            .filter(|text| text.to_lowercase() == "b")
            .count(),
        1
    );
}

#[tokio::test]
async fn blank_searches_are_ignored_and_clearing_is_per_kind() {
    let library = memory();
    library
        .add_search(MediaKind::Anime, "naruto")
        .await
        .unwrap();
    library
        .add_search(MediaKind::Manga, "berserk")
        .await
        .unwrap();
    library.add_search(MediaKind::Anime, "   ").await.unwrap();
    assert_eq!(
        library.searches(MediaKind::Anime).await.unwrap(),
        vec!["naruto"]
    );
    library.clear_searches(MediaKind::Anime).await.unwrap();
    assert!(library.searches(MediaKind::Anime).await.unwrap().is_empty());
    assert_eq!(
        library.searches(MediaKind::Manga).await.unwrap(),
        vec!["berserk"]
    );
}

#[tokio::test]
async fn moving_entries_changes_the_kind_of_favorites_history_and_order() {
    let library = memory();
    library
        .toggle_favorite(favorite(1, MediaKind::Manga))
        .await
        .unwrap();
    library
        .toggle_favorite(favorite(2, MediaKind::Manga))
        .await
        .unwrap();
    let mut entry = progress(1, 3.0, 5.0, 10);
    entry.kind = MediaKind::Manga;
    library.save_progress(entry).await.unwrap();
    library
        .set_unit_order(MediaKind::Manga, &media(1), UnitOrder::Desc)
        .await
        .unwrap();
    let moved = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(1)])
        .await
        .unwrap();
    assert_eq!(moved, 3);
    assert!(
        library
            .is_favorite(MediaKind::Novel, &media(1))
            .await
            .unwrap()
    );
    assert!(
        !library
            .is_favorite(MediaKind::Manga, &media(1))
            .await
            .unwrap()
    );
    assert!(
        library
            .is_favorite(MediaKind::Manga, &media(2))
            .await
            .unwrap()
    );
    let novels = library.history(MediaKind::Novel).await.unwrap();
    assert_eq!(novels[0].entry.kind, MediaKind::Novel);
    let order = library
        .unit_order(MediaKind::Novel, &media(1))
        .await
        .unwrap();
    assert_eq!(order, UnitOrder::Desc);
    let again = library
        .move_entries(MediaKind::Manga, MediaKind::Novel, &[media(1)])
        .await
        .unwrap();
    assert_eq!(again, 0);
}
