use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::ChapterText;

use super::CallRecorder;
use crate::ports::{BoxFuture, TextSource};

#[derive(Default)]
pub struct FakeText {
    chapters: HashMap<String, ChapterText>,
    recorder: CallRecorder,
}

impl FakeText {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_chapter(mut self, chapter: &str, language: &str, paragraphs: &[&str]) -> Self {
        let text = ChapterText::from_paragraphs(
            language,
            paragraphs.iter().map(|paragraph| paragraph.to_string()),
        );
        self.chapters.insert(chapter.to_string(), text);
        self
    }

    pub fn set_failure(&self, error: Option<SourceError>) {
        self.recorder.set_failure(error);
    }

    pub fn calls(&self) -> Vec<String> {
        self.recorder.calls()
    }
}

impl TextSource for FakeText {
    fn chapter_text(&self, chapter: String) -> BoxFuture<'_, Result<ChapterText, SourceError>> {
        Box::pin(async move {
            self.recorder.enter(format!("text {chapter}"))?;
            self.chapters
                .get(&chapter)
                .cloned()
                .ok_or(SourceError::NotFound(chapter))
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn known_chapters_return_their_text_and_unknown_ones_are_not_found() {
        let text = FakeText::new().with_chapter("c1", "id", &["Halo", "Dunia"]);
        let found = text.chapter_text("c1".into()).await.unwrap();
        assert_eq!(found.language, "id");
        assert_eq!(found.paragraphs().count(), 2);
        assert!(matches!(
            text.chapter_text("c2".into()).await,
            Err(SourceError::NotFound(_))
        ));
        assert_eq!(text.calls(), vec!["text c1", "text c2"]);
    }

    #[tokio::test]
    async fn a_switched_on_failure_is_returned_for_every_chapter() {
        let text = FakeText::new().with_chapter("c1", "id", &["Halo"]);
        text.set_failure(Some(SourceError::Unavailable("down".into())));
        assert!(matches!(
            text.chapter_text("c1".into()).await,
            Err(SourceError::Unavailable(_))
        ));
    }
}
