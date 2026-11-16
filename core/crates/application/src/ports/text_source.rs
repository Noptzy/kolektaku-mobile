use domain::error::SourceError;
use domain::source::ChapterText;

use super::BoxFuture;

pub trait TextSource: Send + Sync {
    fn chapter_text(&self, chapter: String) -> BoxFuture<'_, Result<ChapterText, SourceError>>;
}
