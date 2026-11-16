use std::sync::Mutex;

use domain::error::SourceError;
use domain::translation::{LanguageRoute, TranslationReply};

use crate::ports::{BoxFuture, Translator};

type Script = Box<dyn Fn(usize, &[String]) -> Result<TranslationReply, SourceError> + Send + Sync>;

pub struct FakeTranslator {
    script: Script,
    calls: Mutex<Vec<Vec<String>>>,
    routes: Mutex<Vec<LanguageRoute>>,
}

impl FakeTranslator {
    pub fn scripted(
        script: impl Fn(usize, &[String]) -> Result<TranslationReply, SourceError>
        + Send
        + Sync
        + 'static,
    ) -> Self {
        Self {
            script: Box::new(script),
            calls: Mutex::new(Vec::new()),
            routes: Mutex::new(Vec::new()),
        }
    }

    pub fn prefixing(prefix: &'static str) -> Self {
        Self::scripted(move |_, lines| {
            Ok(TranslationReply::new(
                lines.iter().map(|line| format!("{prefix}{line}")).collect(),
                Some("en".into()),
            ))
        })
    }

    pub fn failing_with(error: SourceError) -> Self {
        Self::scripted(move |_, _| Err(error.clone()))
    }

    pub fn calls(&self) -> Vec<Vec<String>> {
        self.calls.lock().unwrap().clone()
    }

    pub fn routes(&self) -> Vec<LanguageRoute> {
        self.routes.lock().unwrap().clone()
    }
}

impl Translator for FakeTranslator {
    fn translate(
        &self,
        lines: Vec<String>,
        route: LanguageRoute,
    ) -> BoxFuture<'_, Result<TranslationReply, SourceError>> {
        let call_index = {
            let mut calls = self.calls.lock().unwrap();
            calls.push(lines.clone());
            calls.len() - 1
        };
        self.routes.lock().unwrap().push(route);
        let result = (self.script)(call_index, &lines);
        Box::pin(async move { result })
    }
}

#[cfg(test)]
mod tests {
    use domain::settings::TranslationLanguage;

    use super::*;

    fn route() -> LanguageRoute {
        LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap()
    }

    #[tokio::test]
    async fn prefixing_marks_every_line_and_records_the_call() {
        let fake = FakeTranslator::prefixing("T:");
        let reply = fake.translate(vec!["a".into(), "b".into()], route()).await;
        assert_eq!(reply.unwrap().lines, vec!["T:a", "T:b"]);
        assert_eq!(fake.calls(), vec![vec!["a".to_string(), "b".to_string()]]);
        assert_eq!(fake.routes(), vec![route()]);
    }

    #[tokio::test]
    async fn a_failing_fake_returns_its_error_every_time() {
        let fake = FakeTranslator::failing_with(SourceError::QuotaExceeded);
        let reply = fake.translate(vec!["a".into()], route()).await;
        assert_eq!(reply, Err(SourceError::QuotaExceeded));
    }

    #[tokio::test]
    async fn the_script_sees_the_call_number() {
        let fake = FakeTranslator::scripted(|call, lines| {
            Ok(TranslationReply::new(
                vec![format!("{call}"); lines.len()],
                None,
            ))
        });
        fake.translate(vec!["x".into()], route()).await.unwrap();
        let second = fake.translate(vec!["y".into()], route()).await.unwrap();
        assert_eq!(second.lines, vec!["1"]);
    }
}
