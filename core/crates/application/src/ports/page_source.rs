use domain::error::SourceError;
use domain::source::ChapterPages;

use super::BoxFuture;

pub trait PageSource: Send + Sync {
    fn chapter_pages(&self, chapter: String) -> BoxFuture<'_, Result<ChapterPages, SourceError>>;
}
