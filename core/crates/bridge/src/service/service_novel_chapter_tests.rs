use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::{FakeSource, FakeText};
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::settings::TranslationLanguage;
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore, Unit};

use super::play;
use super::service_support::{Folder, catalog_ref, offline, state_with};
use crate::state::AppState;
use application::testing::FakeCatalog;

fn novel_site(language: &str) -> FakeSource {
    let text = FakeText::new().with_chapter("n-ch-2", language, &["Satu", "Dua"]);
    FakeSource::new("n", MediaKind::Novel)
        .with_units(
            "n-item",
            vec![
                Unit::new("n-ch-1", 1.0, "Chapter 1"),
                Unit::new("n-ch-2", 2.0, "Chapter 2"),
            ],
        )
        .with_text(text)
}

async fn linked_state(folder: &Folder, language: &str) -> AppState<FakeCatalog> {
    let providers: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(novel_site(language))];
    let state = state_with(folder, providers, offline()).await;
    let reference = MediaRef::catalog(MediaId::new(140960).unwrap());
    let link = SourceLink::matched(
        SourceId::new("n"),
        ItemId::new("n-item"),
        Confidence::new(0.9),
        0,
    );
    state.links.save_all(&reference, vec![link]).await.unwrap();
    state
}

#[tokio::test]
async fn a_chapter_is_opened_as_blocks_with_its_language() {
    let folder = Folder::new();
    let state = linked_state(&folder, "id").await;
    let chapter = play::open_novel_chapter(&state, &catalog_ref(), 2.0, None, Vec::new())
        .await
        .unwrap();
    assert_eq!(chapter.source, "n");
    assert_eq!(chapter.unit.number, 2.0);
    assert_eq!(chapter.language, "id");
    let texts: Vec<&str> = chapter.blocks.iter().map(|b| b.text.as_str()).collect();
    assert_eq!(texts, vec!["Satu", "Dua"]);
    assert!(chapter.blocks.iter().all(|block| !block.is_image));
    assert!(chapter.translated_language.is_none() && chapter.translated_blocks.is_empty());
}

#[tokio::test]
async fn an_english_chapter_offline_keeps_its_text_and_reports_the_failed_translation() {
    let folder = Folder::new();
    let state = linked_state(&folder, "en").await;
    assert_eq!(
        state.settings.get().translation,
        TranslationLanguage::Indonesian
    );
    let chapter = play::open_novel_chapter(&state, &catalog_ref(), 2.0, None, Vec::new())
        .await
        .unwrap();
    assert_eq!(chapter.language, "en");
    assert!(chapter.translation_failed);
    assert!(chapter.translated_language.is_none() && chapter.translated_blocks.is_empty());
    assert_eq!(chapter.blocks.len(), 2);
}

#[tokio::test]
async fn preloading_reports_whether_the_next_chapter_could_be_read() {
    let folder = Folder::new();
    let state = linked_state(&folder, "id").await;
    assert!(play::preload_novel_chapter(&state, &catalog_ref(), 2.0, None).await);
    assert!(!play::preload_novel_chapter(&state, &catalog_ref(), 9.0, None).await);
}

#[tokio::test]
async fn an_unknown_reference_is_an_error_not_a_panic() {
    let folder = Folder::new();
    let state = linked_state(&folder, "id").await;
    let bad = crate::dto::media::MediaRefDto::catalog(0);
    let result = play::open_novel_chapter(&state, &bad, 1.0, None, Vec::new()).await;
    assert!(result.is_err());
}
