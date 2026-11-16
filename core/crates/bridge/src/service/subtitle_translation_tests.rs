use std::sync::Arc;

use application::ports::TranslationHealth;
use application::testing::{FakeCatalog, FakeTranslator};
use domain::error::SourceError;
use domain::settings::{AppSettings, TranslationLanguage};
use infrastructure::http::HttpResponse;

use super::service_support::{Folder, ScriptedHttp, state_with};
use super::subtitle::cues;
use crate::state::AppState;

const FILE: &str = "WEBVTT\n\n00:01.000 --> 00:02.000\nHello\n\n00:03.000 --> 00:04.000\nWhat are you\ntalking about?\n\n00:05.000 --> 00:06.000\n\u{266a}\n";
const ADDRESS: &str = "https://subs.test/a.vtt";

struct PausedUntil(Option<u64>);

impl TranslationHealth for PausedUntil {
    fn paused_until(&self) -> Option<u64> {
        self.0
    }
}

async fn state_with_translator(
    folder: &Folder,
    translator: Arc<FakeTranslator>,
    paused: Option<u64>,
) -> AppState<FakeCatalog> {
    let served = ScriptedHttp(Ok(HttpResponse::new(200, FILE)));
    let state = state_with(folder, Vec::new(), served).await;
    state.with_translator(translator, Arc::new(PausedUntil(paused)))
}

async fn switch_translation(state: &AppState<FakeCatalog>, language: TranslationLanguage) {
    let settings = AppSettings {
        translation: language,
        ..AppSettings::default()
    };
    state
        .settings
        .save(state.library.as_ref(), settings)
        .await
        .unwrap();
}

#[tokio::test]
async fn an_english_track_comes_back_in_indonesian_with_the_same_times() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("ID:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    let plan = cues(&state, ADDRESS, &[], Some("en"), 0, true)
        .await
        .unwrap();
    assert!(plan.translated && !plan.failed);
    assert_eq!(plan.cues[0].text, "ID:Hello");
    assert_eq!(plan.cues[1].text, "ID:What are you talking about?");
    assert_eq!(plan.cues[2].text, "\u{266a}");
    assert_eq!((plan.cues[1].start_ms, plan.cues[1].end_ms), (3_000, 4_000));
    assert_eq!(fake.routes()[0].from_code(), Some("en"));
    assert_eq!(fake.routes()[0].target_code(), "id");
}

#[tokio::test]
async fn a_track_already_in_the_target_language_is_left_alone() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("ID:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    let plan = cues(&state, ADDRESS, &[], Some("id"), 0, true)
        .await
        .unwrap();
    assert!(!plan.translated);
    assert_eq!(plan.cues[0].text, "Hello");
    assert!(fake.calls().is_empty());
}

#[tokio::test]
async fn a_track_of_unknown_language_asks_the_service_to_detect_it() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("ID:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    cues(&state, ADDRESS, &[], None, 0, true).await.unwrap();
    assert_eq!(fake.routes()[0].from_code(), None);
}

#[tokio::test]
async fn with_translation_off_nothing_is_ever_sent() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("ID:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    switch_translation(&state, TranslationLanguage::Off).await;
    let plan = cues(&state, ADDRESS, &[], Some("en"), 0, true)
        .await
        .unwrap();
    assert!(!plan.translated && !plan.failed);
    assert_eq!(plan.cues[0].text, "Hello");
    assert!(fake.calls().is_empty());
}

#[tokio::test]
async fn another_target_language_is_used_when_chosen() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("JA:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    switch_translation(&state, TranslationLanguage::Japanese).await;
    cues(&state, ADDRESS, &[], Some("en"), 0, true)
        .await
        .unwrap();
    assert_eq!(fake.routes()[0].target_code(), "ja");
}

#[tokio::test]
async fn a_failed_translation_keeps_the_original_text_and_says_so() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::failing_with(SourceError::Network(
        "x".into(),
    )));
    let state = state_with_translator(&folder, fake, None).await;
    let plan = cues(&state, ADDRESS, &[], Some("en"), 0, true)
        .await
        .unwrap();
    assert!(plan.failed && !plan.translated);
    assert_eq!(plan.cues[0].text, "Hello");
    assert_eq!(plan.retry_at_secs, None);
}

#[tokio::test]
async fn a_paused_service_reports_when_it_will_be_back() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::failing_with(SourceError::RateLimited {
        retry_after_secs: None,
    }));
    let state = state_with_translator(&folder, fake, Some(1_600)).await;
    let plan = cues(&state, ADDRESS, &[], Some("en"), 0, true)
        .await
        .unwrap();
    assert!(plan.failed);
    assert_eq!(plan.retry_at_secs, Some(1_600));
}

#[tokio::test]
async fn the_part_at_the_playback_position_is_asked_first() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("ID:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    cues(&state, ADDRESS, &[], Some("en"), 3_500, true)
        .await
        .unwrap();
    assert_eq!(fake.calls().len(), 1);
}

#[tokio::test]
async fn asking_without_translation_returns_the_original_and_sends_nothing() {
    let folder = Folder::new();
    let fake = Arc::new(FakeTranslator::prefixing("ID:"));
    let state = state_with_translator(&folder, fake.clone(), None).await;
    let plan = cues(&state, ADDRESS, &[], Some("en"), 0, false)
        .await
        .unwrap();
    assert!(!plan.translated && !plan.failed);
    assert_eq!(
        plan.cues[1].text,
        "What are you
talking about?"
    );
    assert!(fake.calls().is_empty());
}
