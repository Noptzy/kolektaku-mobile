use std::sync::Arc;

use domain::error::StorageError;
use domain::library::{LibraryRepository, Progress};
use domain::media::{MediaKind, MediaRef};

pub struct ContinueList<L: LibraryRepository> {
    library: Arc<L>,
}

impl<L: LibraryRepository> ContinueList<L> {
    pub fn new(library: Arc<L>) -> Self {
        Self { library }
    }

    pub async fn execute(&self, kind: MediaKind) -> Result<Vec<Progress>, StorageError> {
        let newest_first = self.library.history(kind).await?;
        let mut seen: Vec<MediaRef> = Vec::new();
        let mut unfinished = Vec::new();
        for progress in newest_first {
            if seen.contains(&progress.entry.media) {
                continue;
            }
            seen.push(progress.entry.media.clone());
            if !progress.completed {
                unfinished.push(progress);
            }
        }
        Ok(unfinished)
    }
}
