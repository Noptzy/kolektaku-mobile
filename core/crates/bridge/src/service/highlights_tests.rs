use super::highlights::{add, all, for_chapter, remove};
use super::service_support::{Folder, state};
use crate::dto::highlight::HighlightInputDto;
use crate::dto::media::MediaRefDto;

fn input(chapter: f64, block: u32) -> HighlightInputDto {
    HighlightInputDto {
        reference: MediaRefDto::catalog(7),
        title: "Hyouka".into(),
        cover_url: None,
        chapter,
        chapter_label: format!("Chapter {chapter}"),
        block,
        start: 0,
        end: 5,
        quote: "quote".into(),
        language: "en".into(),
    }
}

#[tokio::test]
async fn a_highlight_is_added_listed_for_its_chapter_and_removed() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let id = add(&state, &input(1.0, 3)).await.unwrap();
    assert!(id > 0);
    add(&state, &input(2.0, 0)).await.unwrap();
    let here = for_chapter(&state, &MediaRefDto::catalog(7), 1.0)
        .await
        .unwrap();
    assert_eq!(here.len(), 1);
    assert_eq!(here[0].block, 3);
    assert_eq!(all(&state).await.unwrap().len(), 2);
    remove(&state, id).await.unwrap();
    assert_eq!(all(&state).await.unwrap().len(), 1);
}

#[tokio::test]
async fn an_unusable_selection_is_not_stored_and_a_bad_reference_is_refused() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let mut empty = input(1.0, 0);
    empty.end = empty.start;
    assert_eq!(add(&state, &empty).await.unwrap(), 0);
    let mut bad = input(1.0, 0);
    bad.reference.id = 0;
    assert!(add(&state, &bad).await.is_err());
    assert!(all(&state).await.unwrap().is_empty());
}
