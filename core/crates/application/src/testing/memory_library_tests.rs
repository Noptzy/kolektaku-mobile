use domain::library::{FavoriteInput, LibraryRepository, ProgressInput};
use domain::media::{MediaId, MediaKind, MediaRef};

use super::MemoryLibrary;
fn progress(id: u64, unit: f64, position: f64, at: u64) -> ProgressInput {
    ProgressInput {
        media: MediaRef::catalog(MediaId::new(id).unwrap()),
        kind: MediaKind::Anime,
        unit_number: unit,
        title: "t".into(),
        cover_url: None,
        position,
        length: 100.0,
        updated_at_secs: at,
    }
}

#[tokio::test]
async fn progress_is_kept_per_unit_newest_first() {
    let library = MemoryLibrary::new();
    library
        .save_progress(progress(1, 1.0, 10.0, 1))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 2.0, 95.0, 2))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 1.0, 20.0, 3))
        .await
        .unwrap();
    let history = library.history(MediaKind::Anime).await.unwrap();
    assert_eq!(history.len(), 2);
    assert_eq!(history[0].entry.unit_number, 1.0);
    assert!(history[1].completed);
}

#[tokio::test]
async fn favorites_and_preferences_round_trip() {
    let library = MemoryLibrary::new();
    let media = MediaRef::catalog(MediaId::new(1).unwrap());
    let input = FavoriteInput {
        media: media.clone(),
        kind: MediaKind::Anime,
        title: "t".into(),
        cover_url: None,
    };
    assert!(library.toggle_favorite(input.clone()).await.unwrap());
    assert!(library.is_favorite(MediaKind::Anime, &media).await.unwrap());
    assert!(!library.toggle_favorite(input).await.unwrap());
    library.set_preference("k", "v").await.unwrap();
    assert_eq!(library.preference("k").await.unwrap().as_deref(), Some("v"));
}
