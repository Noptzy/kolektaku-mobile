use std::sync::Arc;

use application::ports::Translator;
use domain::settings::TranslationLanguage;
use domain::translation::LanguageRoute;
use infrastructure::http::ReqwestClient;
use infrastructure::translate::google::GoogleTranslator;

fn live_translator() -> GoogleTranslator {
    GoogleTranslator::new(Arc::new(ReqwestClient::standard().unwrap()))
}

#[tokio::test]
#[ignore = "talks to the real translation service"]
async fn three_english_lines_come_back_as_three_indonesian_lines() {
    let route = LanguageRoute::new(Some("en"), TranslationLanguage::Indonesian).unwrap();
    let lines = vec![
        "Hello, how are you?".to_string(),
        "I'm fine, thank you.".to_string(),
        "See you tomorrow!".to_string(),
    ];
    let reply = live_translator()
        .translate(lines.clone(), route)
        .await
        .unwrap();
    assert!(reply.answers(3));
    assert!(
        reply
            .lines
            .iter()
            .zip(&lines)
            .all(|(out, original)| out != original)
    );
}

#[tokio::test]
#[ignore = "talks to the real translation service"]
async fn the_source_language_can_be_detected() {
    let route = LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap();
    let reply = live_translator()
        .translate(vec!["Where is the library?".to_string()], route)
        .await
        .unwrap();
    assert_eq!(reply.detected_from.as_deref(), Some("en"));
}
