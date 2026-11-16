use std::collections::HashMap;
use std::sync::Mutex;

use domain::error::StorageError;
use domain::media::{MediaKind, MediaRef};

use crate::ports::{LedgerEntry, UpdateLedger};

#[derive(Default)]
pub struct MemoryUpdateLedger {
    entries: Mutex<HashMap<(MediaKind, MediaRef), LedgerEntry>>,
}

impl MemoryUpdateLedger {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn entry(&self, kind: MediaKind, media: &MediaRef) -> Option<LedgerEntry> {
        self.entries
            .lock()
            .unwrap()
            .get(&(kind, media.clone()))
            .copied()
    }
}

impl UpdateLedger for MemoryUpdateLedger {
    async fn seen(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<Option<LedgerEntry>, StorageError> {
        Ok(self.entry(kind, media))
    }

    async fn record(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        latest: f64,
        checked_at: u64,
    ) -> Result<(), StorageError> {
        self.entries
            .lock()
            .unwrap()
            .insert((kind, media.clone()), LedgerEntry { latest, checked_at });
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use domain::media::MediaId;

    use super::*;

    #[tokio::test]
    async fn what_is_recorded_is_seen_and_replaced() {
        let ledger = MemoryUpdateLedger::new();
        let media = MediaRef::catalog(MediaId::new(1).unwrap());
        assert_eq!(ledger.seen(MediaKind::Anime, &media).await.unwrap(), None);
        ledger
            .record(MediaKind::Anime, &media, 5.0, 10)
            .await
            .unwrap();
        ledger
            .record(MediaKind::Anime, &media, 6.0, 20)
            .await
            .unwrap();
        let entry = ledger
            .seen(MediaKind::Anime, &media)
            .await
            .unwrap()
            .unwrap();
        assert_eq!((entry.latest, entry.checked_at), (6.0, 20));
        assert_eq!(ledger.seen(MediaKind::Manga, &media).await.unwrap(), None);
    }
}
