use domain::download::{DownloadLedger, DownloadPhase};
use domain::error::StorageError;

use super::queue::DownloadQueue;

impl<L: DownloadLedger + 'static> DownloadQueue<L> {
    pub async fn remove(&self, id: i64, delete_file: bool) -> Result<(), StorageError> {
        self.cancel(id).await?;
        let removed = self.board.lock().unwrap().remove(id);
        self.ledger.remove(id).await?;
        if let Some(path) = removed
            .and_then(|job| job.file_path)
            .filter(|_| delete_file)
        {
            self.downloader.discard(path).await;
        }
        Ok(())
    }

    pub async fn relocate(&self, id: i64, path: String) -> Result<(), StorageError> {
        let Some(mut job) = self.board.lock().unwrap().get(id) else {
            return Ok(());
        };
        if job.phase != DownloadPhase::Done || path.trim().is_empty() {
            return Ok(());
        }
        job.file_path = Some(path);
        self.board.lock().unwrap().put(job.clone());
        self.ledger.update(job).await
    }
}
