use std::future::Future;

use domain::error::StorageError;
use domain::media::{MediaKind, MediaRef};

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct LedgerEntry {
    pub latest: f64,
    pub checked_at: u64,
}

pub trait UpdateLedger: Send + Sync {
    fn seen(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> impl Future<Output = Result<Option<LedgerEntry>, StorageError>> + Send;

    fn record(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        latest: f64,
        checked_at: u64,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;
}
