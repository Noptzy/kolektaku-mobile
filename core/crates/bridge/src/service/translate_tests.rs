use std::sync::Arc;

use application::ports::TranslationHealth;
use application::testing::{FakeCatalog, FakeTranslator};
use domain::error::SourceError;
use domain::settings::{AppSettings, TranslationLanguage};
use domain::translation::TranslationReply;

use super::service_support::{Folder, offline, state_with};
use super::translate::{paused_until, texts};
use crate::state::AppState;

struct PausedUntil(Option<u64>);

impl TranslationHealth for PausedUntil {
    fn paused_until(&self) -> Option<u64> {
        self.0
    }
}

async fn state_with_translator(
    folder: &Folder,
    translator: FakeTranslator,
    paused: Option<u64>,
) -> (AppState<FakeCatalog>, Arc<FakeTranslator>) {
    let fake = Arc::new(translator);
    let state = state_with(folder, Vec::new(), offline()).await;
    (
        state.with_translator(fake.clone(), Arc::new(PausedUntil(paused))),
        fake,
    )
}

fn lines(items: &[&str]) -> Vec<String> {
    items.iter().map(|item| item.to_string()).collect()
}

#[tokio::test]
async fn many_texts_go_out_in_one_request_and_come_back_in_order() {
    let folder = Folder::new();
    let (state, fake) =
        state_with_translator(&folder, FakeTranslator::prefixing("ID:"), None).await;
    let result = texts(&state, lines(&["one", "two", "three"])).await;
    assert_eq!(result.texts, vec!["ID:one", "ID:two", "ID:three"]);
    assert!(result.translated && !result.failed);
    assert_eq!(fake.calls().len(), 1);
    assert_eq!(fake.routes()[0].from_code(), None);
    assert_eq!(fake.routes()[0].target_code(), "id");
}

#[tokio::test]
async fn text_already_in_the_target_language_comes_back_unlabelled() {
    let folder = Folder::new();
    let same = FakeTranslator::scripted(|_, lines| {
        Ok(TranslationReply::new(
            lines.iter().map(|line| format!("ID:{line}")).collect(),
            Some("id".into()),
        ))
    });
    let (state, _) = state_with_translator(&folder, same, None).await;
    let result = texts(&state, lines(&["Halo dunia"])).await;
    assert_eq!(result.texts, vec!["Halo dunia"]);
    assert!(!result.translated);
}

#[tokio::test]
async fn with_translation_off_nothing_is_sent() {
    let folder = Folder::new();
    let (state, fake) =
        state_with_translator(&folder, FakeTranslator::prefixing("ID:"), None).await;
    let settings = AppSettings {
        translation: TranslationLanguage::Off,
        ..AppSettings::default()
    };
    state
        .settings
        .save(state.library.as_ref(), settings)
        .await
        .unwrap();
    let result = texts(&state, lines(&["one"])).await;
    assert_eq!(result.texts, vec!["one"]);
    assert!(!result.translated && !result.failed);
    assert!(fake.calls().is_empty());
}

#[tokio::test]
async fn a_failing_service_leaves_the_texts_and_says_so() {
    let folder = Folder::new();
    let failing = FakeTranslator::failing_with(SourceError::Network("x".into()));
    let (state, _) = state_with_translator(&folder, failing, None).await;
    let result = texts(&state, lines(&["one"])).await;
    assert_eq!(result.texts, vec!["one"]);
    assert!(result.failed && !result.translated);
}

#[tokio::test]
async fn nothing_to_translate_sends_nothing() {
    let folder = Folder::new();
    let (state, fake) =
        state_with_translator(&folder, FakeTranslator::prefixing("ID:"), None).await;
    let result = texts(&state, Vec::new()).await;
    assert!(result.texts.is_empty() && !result.translated);
    assert!(fake.calls().is_empty());
}

#[tokio::test]
async fn the_pause_time_is_read_from_the_health_port() {
    let folder = Folder::new();
    let (state, _) =
        state_with_translator(&folder, FakeTranslator::prefixing("ID:"), Some(1_600)).await;
    assert_eq!(paused_until(&state), Some(1_600));
    let (calm, _) = state_with_translator(&folder, FakeTranslator::prefixing("ID:"), None).await;
    assert_eq!(paused_until(&calm), None);
}
