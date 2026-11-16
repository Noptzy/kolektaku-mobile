use std::sync::Arc;

use domain::error::SourceError;
use domain::settings::TranslationLanguage;
use domain::translation::{LanguageRoute, TranslationReply};

use super::{MAX_REQUESTS_PER_FILE, TranslateLines};
use crate::testing::FakeTranslator;

fn to_indonesian() -> LanguageRoute {
    LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap()
}

fn numbered(count: usize) -> Vec<String> {
    (0..count).map(|index| format!("line {index}")).collect()
}

async fn run(
    fake: Arc<FakeTranslator>,
    lines: Vec<String>,
    start_at: usize,
) -> super::LineTranslation {
    TranslateLines::new(fake)
        .execute(lines, &to_indonesian(), start_at)
        .await
}

#[tokio::test]
async fn every_line_comes_back_translated_in_the_same_order() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(fake.clone(), vec!["a".into(), "b".into(), "c".into()], 0).await;
    assert_eq!(result.lines, vec!["T:a", "T:b", "T:c"]);
    assert!(result.translated && !result.failed);
    assert_eq!(result.requests, 1);
    assert_eq!(result.detected_from.as_deref(), Some("en"));
}

#[tokio::test]
async fn at_most_two_hundred_lines_travel_in_one_request() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(fake.clone(), numbered(450), 0).await;
    let sizes: Vec<_> = fake.calls().iter().map(Vec::len).collect();
    assert_eq!(sizes, vec![200, 200, 50]);
    assert_eq!(result.lines.len(), 450);
    assert!(result.lines.iter().all(|line| line.starts_with("T:")));
}

#[tokio::test]
async fn requests_stop_at_the_twelfth_and_the_rest_stays_original() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let total = MAX_REQUESTS_PER_FILE * 200 + 30;
    let result = run(fake.clone(), numbered(total), 0).await;
    assert_eq!(fake.calls().len(), MAX_REQUESTS_PER_FILE);
    assert_eq!(result.requests, MAX_REQUESTS_PER_FILE);
    assert!(result.lines[total - 1].starts_with("line "));
    assert!(result.lines[0].starts_with("T:"));
}

#[tokio::test]
async fn repeated_text_is_sent_once_and_restored_everywhere() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let lines = vec!["hi".into(), "bye".into(), "hi".into(), "hi".into()];
    let result = run(fake.clone(), lines, 0).await;
    assert_eq!(
        fake.calls(),
        vec![vec!["hi".to_string(), "bye".to_string()]]
    );
    assert_eq!(result.lines, vec!["T:hi", "T:bye", "T:hi", "T:hi"]);
}

#[tokio::test]
async fn blank_lines_are_never_sent_and_stay_blank() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let lines = vec!["a".into(), "".into(), "   ".into(), "b".into()];
    let result = run(fake.clone(), lines, 0).await;
    assert_eq!(fake.calls(), vec![vec!["a".to_string(), "b".to_string()]]);
    assert_eq!(result.lines, vec!["T:a", "", "   ", "T:b"]);
}

#[tokio::test]
async fn an_answer_with_the_wrong_count_leaves_that_part_original() {
    let fake = Arc::new(FakeTranslator::scripted(|call, lines| {
        let answer = if call == 0 {
            lines[1..].to_vec()
        } else {
            lines.to_vec()
        };
        Ok(TranslationReply::new(
            answer.iter().map(|line| format!("T:{line}")).collect(),
            None,
        ))
    }));
    let result = run(fake, numbered(300), 0).await;
    assert_eq!(result.lines[0], "line 0");
    assert_eq!(result.lines[199], "line 199");
    assert_eq!(result.lines[200], "T:line 200");
    assert!(result.translated && !result.failed);
}

#[tokio::test]
async fn a_failure_stops_asking_and_keeps_what_was_already_translated() {
    let fake = Arc::new(FakeTranslator::scripted(|call, lines| {
        if call == 1 {
            return Err(SourceError::RateLimited {
                retry_after_secs: None,
            });
        }
        Ok(TranslationReply::new(
            lines.iter().map(|line| format!("T:{line}")).collect(),
            None,
        ))
    }));
    let result = run(fake.clone(), numbered(600), 0).await;
    assert_eq!(fake.calls().len(), 2);
    assert!(result.failed && result.translated);
    assert_eq!(result.lines[0], "T:line 0");
    assert_eq!(result.lines[250], "line 250");
    assert_eq!(result.lines[599], "line 599");
}

#[tokio::test]
async fn a_first_request_that_fails_leaves_everything_original() {
    let fake = Arc::new(FakeTranslator::failing_with(SourceError::Network(
        "x".into(),
    )));
    let lines = numbered(5);
    let result = run(fake, lines.clone(), 0).await;
    assert_eq!(result.lines, lines);
    assert!(result.failed && !result.translated);
}

#[tokio::test]
async fn text_already_in_the_target_language_is_not_even_asked() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let route = LanguageRoute::new(Some("id"), TranslationLanguage::Indonesian).unwrap();
    let lines = numbered(3);
    let result = TranslateLines::new(fake.clone())
        .execute(lines.clone(), &route, 0)
        .await;
    assert!(fake.calls().is_empty());
    assert_eq!(result.lines, lines);
    assert!(!result.translated && result.requests == 0);
}

#[tokio::test]
async fn a_detected_source_equal_to_the_target_returns_the_original_unlabelled() {
    let fake = Arc::new(FakeTranslator::scripted(|_, lines| {
        Ok(TranslationReply::new(
            lines.iter().map(|line| format!("T:{line}")).collect(),
            Some("id".into()),
        ))
    }));
    let lines = numbered(2);
    let result = run(fake, lines.clone(), 0).await;
    assert_eq!(result.lines, lines);
    assert!(!result.translated);
    assert_eq!(result.detected_from.as_deref(), Some("id"));
}

#[tokio::test]
async fn the_part_holding_the_playback_position_is_sent_first() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(fake.clone(), numbered(450), 430).await;
    let calls = fake.calls();
    assert_eq!(calls[0][0], "line 400");
    let sizes: Vec<_> = calls.iter().map(Vec::len).collect();
    assert_eq!(sizes, vec![50, 200, 200]);
    assert_eq!(result.lines[0], "T:line 0");
    assert_eq!(result.lines[449], "T:line 449");
}

#[tokio::test]
async fn the_parts_are_the_same_wherever_playback_starts() {
    let first = Arc::new(FakeTranslator::prefixing("T:"));
    let second = Arc::new(FakeTranslator::prefixing("T:"));
    run(first.clone(), numbered(450), 0).await;
    run(second.clone(), numbered(450), 300).await;
    let mut a = first.calls();
    let mut b = second.calls();
    a.sort();
    b.sort();
    assert_eq!(a, b);
}

#[tokio::test]
async fn a_start_past_the_end_is_the_same_as_the_start() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    run(fake.clone(), numbered(3), 99).await;
    assert_eq!(fake.calls()[0][0], "line 0");
}

#[tokio::test]
async fn an_empty_translation_for_a_real_line_keeps_the_original() {
    let fake = Arc::new(FakeTranslator::scripted(|_, lines| {
        Ok(TranslationReply::new(
            vec![String::new(); lines.len()],
            None,
        ))
    }));
    let result = run(fake, vec!["a".into()], 0).await;
    assert_eq!(result.lines, vec!["a"]);
}

#[tokio::test]
async fn nothing_to_translate_asks_nobody() {
    let fake = Arc::new(FakeTranslator::prefixing("T:"));
    let result = run(fake.clone(), vec!["".into(), " ".into()], 0).await;
    assert!(fake.calls().is_empty());
    assert!(!result.translated && !result.failed);
}
