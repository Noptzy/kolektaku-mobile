use std::sync::Arc;

use domain::error::SourceError;
use domain::settings::TranslationLanguage;
use domain::source::{ChapterText, TextBlock};
use domain::translation::LanguageRoute;

use super::TranslateBlocks;
use crate::testing::FakeTranslator;

fn route() -> LanguageRoute {
    LanguageRoute::new(Some("en"), TranslationLanguage::Indonesian).unwrap()
}

fn chapter() -> ChapterText {
    ChapterText::new(
        "en",
        vec![
            TextBlock::Paragraph("One".into()),
            TextBlock::Image("https://img.test/a.jpg".into()),
            TextBlock::Paragraph("Two".into()),
            TextBlock::Paragraph("One".into()),
        ],
    )
}

#[tokio::test]
async fn paragraphs_are_translated_in_place_and_illustrations_stay() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = TranslateBlocks::new(fake.clone())
        .execute(&chapter(), &route())
        .await;
    assert!(result.translated && !result.failed);
    assert_eq!(
        result.blocks,
        vec![
            TextBlock::Paragraph("T:One".into()),
            TextBlock::Image("https://img.test/a.jpg".into()),
            TextBlock::Paragraph("T:Two".into()),
            TextBlock::Paragraph("T:One".into()),
        ]
    );
}

#[tokio::test]
async fn a_repeated_paragraph_is_sent_once() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    TranslateBlocks::new(fake.clone())
        .execute(&chapter(), &route())
        .await;
    assert_eq!(
        fake.calls(),
        vec![vec!["One".to_string(), "Two".to_string()]]
    );
}

#[tokio::test]
async fn a_failed_service_returns_the_original_blocks_with_the_failure_mark() {
    let fake = Arc::new(FakeTranslator::failing_with(SourceError::Network(
        "down".into(),
    )));
    let result = TranslateBlocks::new(fake)
        .execute(&chapter(), &route())
        .await;
    assert!(!result.translated && result.failed);
    assert_eq!(result.blocks, chapter().blocks);
}

#[tokio::test]
async fn the_same_language_is_never_sent() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let same = LanguageRoute::new(Some("id"), TranslationLanguage::Indonesian).unwrap();
    let result = TranslateBlocks::new(fake.clone())
        .execute(&chapter(), &same)
        .await;
    assert!(!result.translated && !result.failed);
    assert!(fake.calls().is_empty());
    assert_eq!(result.blocks, chapter().blocks);
}

#[tokio::test]
async fn a_chapter_of_only_illustrations_sends_nothing() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let only = ChapterText::new(
        "en",
        vec![TextBlock::Image("https://img.test/a.jpg".into())],
    );
    let result = TranslateBlocks::new(fake.clone())
        .execute(&only, &route())
        .await;
    assert!(!result.translated);
    assert!(fake.calls().is_empty());
}
