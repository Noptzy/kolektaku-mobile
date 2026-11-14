use std::sync::Arc;

use domain::library::{LibraryRepository, ProgressInput};
use domain::media::{MediaId, MediaKind, MediaRef};

use super::ContinueList;
use crate::testing::MemoryLibrary;

fn progress(id: u64, unit: f64, position: f64, at: u64) -> ProgressInput {
    ProgressInput {
        media: MediaRef::catalog(MediaId::new(id).unwrap()),
        kind: MediaKind::Anime,
        unit_number: unit,
        title: format!("title {id}"),
        cover_url: None,
        position,
        length: 1440.0,
        updated_at_secs: at,
    }
}

#[tokio::test]
async fn lists_the_most_recent_unfinished_episode_of_each_title() {
    let library = Arc::new(MemoryLibrary::new());
    library
        .save_progress(progress(1, 1.0, 1400.0, 8))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 2.0, 300.0, 9))
        .await
        .unwrap();
    library
        .save_progress(progress(2, 5.0, 1400.0, 10))
        .await
        .unwrap();
    let list = ContinueList::new(library)
        .execute(MediaKind::Anime)
        .await
        .unwrap();
    let shape: Vec<(u64, f64)> = list
        .iter()
        .map(|item| {
            (
                item.entry.media.catalog_id().unwrap().get(),
                item.entry.unit_number,
            )
        })
        .collect();
    assert_eq!(shape, vec![(1, 2.0)]);
}

#[tokio::test]
async fn a_finished_latest_episode_hides_the_title_even_if_an_older_one_was_unfinished() {
    let library = Arc::new(MemoryLibrary::new());
    library
        .save_progress(progress(1, 1.0, 100.0, 1))
        .await
        .unwrap();
    library
        .save_progress(progress(1, 2.0, 1400.0, 2))
        .await
        .unwrap();
    assert!(
        ContinueList::new(library)
            .execute(MediaKind::Anime)
            .await
            .unwrap()
            .is_empty()
    );
}

#[tokio::test]
async fn the_newest_title_comes_first_and_other_kinds_are_not_mixed_in() {
    let library = Arc::new(MemoryLibrary::new());
    library
        .save_progress(progress(1, 1.0, 10.0, 1))
        .await
        .unwrap();
    library
        .save_progress(progress(2, 1.0, 10.0, 5))
        .await
        .unwrap();
    let mut manga = progress(3, 1.0, 10.0, 9);
    manga.kind = MediaKind::Manga;
    library.save_progress(manga).await.unwrap();
    let list = ContinueList::new(library)
        .execute(MediaKind::Anime)
        .await
        .unwrap();
    let ids: Vec<u64> = list
        .iter()
        .map(|item| item.entry.media.catalog_id().unwrap().get())
        .collect();
    assert_eq!(ids, vec![2, 1]);
}
