use std::future::Future;

use super::job::DownloadJob;
use crate::error::StorageError;

pub trait DownloadLedger: Send + Sync {
    fn all(&self) -> impl Future<Output = Result<Vec<DownloadJob>, StorageError>> + Send;
    fn insert(&self, job: DownloadJob) -> impl Future<Output = Result<i64, StorageError>> + Send;
    fn update(&self, job: DownloadJob) -> impl Future<Output = Result<(), StorageError>> + Send;
    fn remove(&self, id: i64) -> impl Future<Output = Result<(), StorageError>> + Send;
}
