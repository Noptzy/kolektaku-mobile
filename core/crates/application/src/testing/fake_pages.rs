use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::ChapterPages;

use super::CallRecorder;
use crate::ports::{BoxFuture, PageSource};

#[derive(Default)]
pub struct FakePages {
    chapters: HashMap<String, ChapterPages>,
    recorder: CallRecorder,
}

impl FakePages {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_chapter(mut self, chapter: &str, urls: &[&str]) -> Self {
        let pages = ChapterPages::from_urls(urls.iter().map(|url| url.to_string()));
        self.chapters.insert(chapter.to_string(), pages);
        self
    }

    pub fn set_failure(&self, error: Option<SourceError>) {
        self.recorder.set_failure(error);
    }

    pub fn calls(&self) -> Vec<String> {
        self.recorder.calls()
    }
}

impl PageSource for FakePages {
    fn chapter_pages(&self, chapter: String) -> BoxFuture<'_, Result<ChapterPages, SourceError>> {
        Box::pin(async move {
            self.recorder.enter(format!("pages {chapter}"))?;
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
    async fn known_chapters_return_their_pages_and_unknown_ones_are_not_found() {
        let pages = FakePages::new().with_chapter("c1", &["https://img.test/1.jpg"]);
        assert_eq!(
            pages.chapter_pages("c1".into()).await.unwrap().pages.len(),
            1
        );
        assert!(matches!(
            pages.chapter_pages("c2".into()).await,
            Err(SourceError::NotFound(_))
        ));
        assert_eq!(pages.calls(), vec!["pages c1", "pages c2"]);
    }

    #[tokio::test]
    async fn a_switched_on_failure_is_returned_for_every_chapter() {
        let pages = FakePages::new().with_chapter("c1", &["https://img.test/1.jpg"]);
        pages.set_failure(Some(SourceError::Unavailable("down".into())));
        assert!(matches!(
            pages.chapter_pages("c1".into()).await,
            Err(SourceError::Unavailable(_))
        ));
    }
}
