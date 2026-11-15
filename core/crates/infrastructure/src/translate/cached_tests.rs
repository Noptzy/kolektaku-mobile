use std::sync::Arc;

use application::ports::{TranslationHealth, Translator};
use application::testing::{FakeClock, FakeTranslator};
use domain::error::SourceError;
use domain::settings::TranslationLanguage;
use domain::translation::{LanguageRoute, TranslationReply};

use super::cached::{CACHE_CAPACITY, CachedTranslator, cache_key};
use super::pause_after_failures::{PAUSE_SECS, ServiceState};
use crate::http::ResponseCache;
use crate::storage::TempFolder;

fn route(target: TranslationLanguage) -> LanguageRoute {
    LanguageRoute::detecting(target).unwrap()
}

fn lines() -> Vec<String> {
    vec!["Hello".into(), "Goodbye".into()]
}

struct Rig {
    cached: CachedTranslator,
    inner: Arc<FakeTranslator>,
    clock: Arc<FakeClock>,
    _folder: TempFolder,
}

fn rig_with(inner: FakeTranslator, name: &str) -> Rig {
    let folder = TempFolder::new(name);
    let clock = Arc::new(FakeClock::at(1_000));
    let cache = Arc::new(ResponseCache::new(
        folder.file("translation"),
        clock.clone(),
        CACHE_CAPACITY,
    ));
    let inner = Arc::new(inner);
    let cached = CachedTranslator::new(inner.clone(), cache, clock.clone());
    Rig {
        cached,
        inner,
        clock,
        _folder: folder,
    }
}

#[tokio::test]
async fn the_first_ask_goes_out_and_the_second_is_answered_from_disk() {
    let rig = rig_with(FakeTranslator::prefixing("T:"), "cached-hit");
    let target = route(TranslationLanguage::Indonesian);
    let first = rig.cached.translate(lines(), target.clone()).await.unwrap();
    let second = rig.cached.translate(lines(), target).await.unwrap();
    assert_eq!(first, second);
    assert_eq!(rig.inner.calls().len(), 1);
    assert_eq!(second.lines, vec!["T:Hello", "T:Goodbye"]);
    assert_eq!(second.detected_from.as_deref(), Some("en"));
}

#[tokio::test]
async fn another_target_language_is_a_different_entry() {
    let rig = rig_with(FakeTranslator::prefixing("T:"), "cached-target");
    rig.cached
        .translate(lines(), route(TranslationLanguage::Indonesian))
        .await
        .unwrap();
    rig.cached
        .translate(lines(), route(TranslationLanguage::Japanese))
        .await
        .unwrap();
    assert_eq!(rig.inner.calls().len(), 2);
}

#[tokio::test]
async fn other_text_is_a_different_entry() {
    let rig = rig_with(FakeTranslator::prefixing("T:"), "cached-text");
    let target = route(TranslationLanguage::Indonesian);
    rig.cached.translate(lines(), target.clone()).await.unwrap();
    rig.cached
        .translate(vec!["Hello".into()], target)
        .await
        .unwrap();
    assert_eq!(rig.inner.calls().len(), 2);
}

#[test]
fn the_key_separates_line_boundaries() {
    let target = route(TranslationLanguage::Indonesian);
    let joined = cache_key(&["ab".to_string()], &target);
    let split = cache_key(&["a".to_string(), "b".to_string()], &target);
    assert_ne!(joined, split);
}

#[tokio::test]
async fn an_answer_with_the_wrong_count_is_not_remembered() {
    let wrong =
        FakeTranslator::scripted(|_, _| Ok(TranslationReply::new(vec!["only one".into()], None)));
    let rig = rig_with(wrong, "cached-wrong");
    let target = route(TranslationLanguage::Indonesian);
    rig.cached.translate(lines(), target.clone()).await.unwrap();
    rig.cached.translate(lines(), target).await.unwrap();
    assert_eq!(rig.inner.calls().len(), 2);
}

#[tokio::test]
async fn failures_are_passed_on_and_not_remembered() {
    let rig = rig_with(
        FakeTranslator::failing_with(SourceError::Network("x".into())),
        "cached-fail",
    );
    let result = rig
        .cached
        .translate(lines(), route(TranslationLanguage::Indonesian))
        .await;
    assert_eq!(result, Err(SourceError::Network("x".into())));
}

#[tokio::test]
async fn three_failures_in_a_row_stop_all_network_for_ten_minutes() {
    let rig = rig_with(
        FakeTranslator::failing_with(SourceError::Network("x".into())),
        "cached-pause",
    );
    let target = route(TranslationLanguage::Indonesian);
    for round in 0..3 {
        let asked = vec![format!("line {round}")];
        rig.cached
            .translate(asked, target.clone())
            .await
            .unwrap_err();
    }
    assert_eq!(rig.inner.calls().len(), 3);
    let blocked = rig
        .cached
        .translate(vec!["another".into()], target.clone())
        .await;
    assert_eq!(
        blocked,
        Err(SourceError::RateLimited {
            retry_after_secs: Some(PAUSE_SECS)
        })
    );
    assert_eq!(rig.inner.calls().len(), 3);
    assert_eq!(
        rig.cached.service_state(),
        ServiceState::PausedUntil(1_000 + PAUSE_SECS)
    );
}

#[tokio::test]
async fn after_the_pause_the_service_is_asked_again() {
    let rig = rig_with(
        FakeTranslator::failing_with(SourceError::Network("x".into())),
        "cached-resume",
    );
    let target = route(TranslationLanguage::Indonesian);
    for round in 0..3 {
        let asked = vec![format!("line {round}")];
        rig.cached
            .translate(asked, target.clone())
            .await
            .unwrap_err();
    }
    rig.clock.advance(PAUSE_SECS);
    assert_eq!(rig.cached.service_state(), ServiceState::Normal);
    rig.cached
        .translate(vec!["fresh".into()], target)
        .await
        .unwrap_err();
    assert_eq!(rig.inner.calls().len(), 4);
}

#[tokio::test]
async fn a_remembered_answer_still_works_while_the_service_is_paused() {
    let script = FakeTranslator::scripted(|call, lines| {
        if call == 0 {
            return Ok(TranslationReply::new(lines.to_vec(), None));
        }
        Err(SourceError::Network("x".into()))
    });
    let rig = rig_with(script, "cached-paused-hit");
    let target = route(TranslationLanguage::Indonesian);
    rig.cached.translate(lines(), target.clone()).await.unwrap();
    for round in 0..3 {
        let asked = vec![format!("new {round}")];
        rig.cached
            .translate(asked, target.clone())
            .await
            .unwrap_err();
    }
    let again = rig.cached.translate(lines(), target).await;
    assert!(again.is_ok());
}

#[tokio::test]
async fn a_success_clears_the_failure_streak() {
    let script = FakeTranslator::scripted(|call, lines| {
        if call == 2 {
            return Ok(TranslationReply::new(lines.to_vec(), None));
        }
        Err(SourceError::Network("x".into()))
    });
    let rig = rig_with(script, "cached-streak");
    let target = route(TranslationLanguage::Indonesian);
    for round in 0..5 {
        let asked = vec![format!("line {round}")];
        let _ = rig.cached.translate(asked, target.clone()).await;
    }
    assert_eq!(rig.cached.service_state(), ServiceState::Normal);
    assert_eq!(rig.inner.calls().len(), 5);
}

#[tokio::test]
async fn the_health_port_reports_when_the_pause_ends() {
    let rig = rig_with(
        FakeTranslator::failing_with(SourceError::Network("x".into())),
        "cached-health",
    );
    assert_eq!(rig.cached.paused_until(), None);
    let target = route(TranslationLanguage::Indonesian);
    for round in 0..3 {
        let asked = vec![format!("line {round}")];
        rig.cached
            .translate(asked, target.clone())
            .await
            .unwrap_err();
    }
    assert_eq!(rig.cached.paused_until(), Some(1_000 + PAUSE_SECS));
}
