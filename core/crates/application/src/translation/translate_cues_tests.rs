use std::sync::Arc;

use domain::error::SourceError;
use domain::settings::TranslationLanguage;
use domain::translation::LanguageRoute;

use super::TranslateCues;
use crate::streaming::Cue;
use crate::testing::FakeTranslator;

fn route() -> LanguageRoute {
    LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap()
}

fn cue(start_ms: u64, end_ms: u64, text: &str) -> Cue {
    Cue {
        start_ms,
        end_ms,
        text: text.into(),
    }
}

async fn run(
    fake: &Arc<FakeTranslator>,
    cues: Vec<Cue>,
    position_ms: u64,
) -> super::CueTranslation {
    TranslateCues::new(fake.clone())
        .execute(cues, &route(), position_ms)
        .await
}

#[tokio::test]
async fn the_times_never_change_only_the_text() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let cues = vec![cue(1_000, 2_000, "Hello"), cue(3_000, 4_500, "Bye")];
    let result = run(&fake, cues, 0).await;
    assert_eq!(
        result.cues,
        vec![cue(1_000, 2_000, "T:Hello"), cue(3_000, 4_500, "T:Bye")]
    );
    assert!(result.translated && !result.failed);
}

#[tokio::test]
async fn a_sentence_over_two_lines_is_sent_as_one() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(&fake, vec![cue(0, 1, "What are you\ntalking about?")], 0).await;
    assert_eq!(
        fake.calls(),
        vec![vec!["What are you talking about?".to_string()]]
    );
    assert_eq!(result.cues[0].text, "T:What are you talking about?");
}

#[tokio::test]
async fn two_speakers_are_sent_apart_and_stay_two_lines() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(&fake, vec![cue(0, 1, "- Hi\n- Hello")], 0).await;
    assert_eq!(
        fake.calls(),
        vec![vec!["- Hi".to_string(), "- Hello".to_string()]]
    );
    assert_eq!(result.cues[0].text, "T:- Hi\nT:- Hello");
}

#[tokio::test]
async fn music_cues_are_not_sent_and_stay_as_they_were() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let cues = vec![cue(0, 1, "\u{266a}"), cue(2, 3, "Hello")];
    let result = run(&fake, cues, 0).await;
    assert_eq!(fake.calls(), vec![vec!["Hello".to_string()]]);
    assert_eq!(result.cues[0].text, "\u{266a}");
    assert_eq!(result.cues[1].text, "T:Hello");
}

#[tokio::test]
async fn the_same_text_is_sent_once_for_the_whole_episode() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let cues = vec![cue(0, 1, "Yes."), cue(2, 3, "No."), cue(4, 5, "Yes.")];
    let result = run(&fake, cues, 0).await;
    assert_eq!(fake.calls()[0], vec!["Yes.".to_string(), "No.".to_string()]);
    assert_eq!(result.cues[2].text, "T:Yes.");
}

#[tokio::test]
async fn the_part_around_the_position_goes_first() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let cues: Vec<Cue> = (0..450)
        .map(|index| cue(index * 1_000, index * 1_000 + 900, &format!("line {index}")))
        .collect();
    run(&fake, cues, 430_000).await;
    assert_eq!(fake.calls()[0][0], "line 400");
}

#[tokio::test]
async fn a_failed_service_returns_the_original_cues() {
    let fake = Arc::new(FakeTranslator::failing_with(SourceError::QuotaExceeded));
    let cues = vec![cue(0, 1, "Hello")];
    let result = run(&fake, cues.clone(), 0).await;
    assert_eq!(result.cues, cues);
    assert!(result.failed && !result.translated);
}

#[tokio::test]
async fn nothing_to_translate_asks_nobody() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let cues = vec![cue(0, 1, "\u{266a}")];
    let result = run(&fake, cues.clone(), 0).await;
    assert!(fake.calls().is_empty());
    assert_eq!(result.cues, cues);
    assert!(!result.translated && !result.failed);
}

#[tokio::test]
async fn no_cues_is_an_empty_result() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(&fake, Vec::new(), 0).await;
    assert!(result.cues.is_empty() && !result.translated);
}
