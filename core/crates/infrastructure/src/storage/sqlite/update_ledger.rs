use application::ports::{LedgerEntry, UpdateLedger};
use domain::error::StorageError;
use domain::media::{MediaKind, MediaRef};
use rusqlite::{OptionalExtension, params};

use super::database::Database;
use super::rows::media_key;

pub struct SqliteUpdateLedger {
    database: Database,
}

impl SqliteUpdateLedger {
    pub fn new(database: Database) -> Self {
        Self { database }
    }
}

impl UpdateLedger for SqliteUpdateLedger {
    async fn seen(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<Option<LedgerEntry>, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| {
                connection
                    .query_row(
                        "SELECT latest, checked_at FROM unit_snapshot \
                         WHERE kind = ?1 AND media_key = ?2",
                        params![kind.as_str(), media_key(&media)?],
                        |row| {
                            Ok(LedgerEntry {
                                latest: row.get(0)?,
                                checked_at: row.get::<_, i64>(1)?.max(0) as u64,
                            })
                        },
                    )
                    .optional()
            })
            .await
    }

    async fn record(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        latest: f64,
        checked_at: u64,
    ) -> Result<(), StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| {
                connection.execute(
                    "INSERT OR REPLACE INTO unit_snapshot(kind, media_key, latest, checked_at) \
                     VALUES (?1, ?2, ?3, ?4)",
                    params![kind.as_str(), media_key(&media)?, latest, checked_at as i64],
                )?;
                Ok(())
            })
            .await
    }
}

#[cfg(test)]
mod tests {
    use domain::media::MediaId;

    use super::*;
    use crate::storage::TempFolder;

    fn media(id: u64) -> MediaRef {
        MediaRef::catalog(MediaId::new(id).unwrap())
    }

    #[tokio::test]
    async fn a_snapshot_is_kept_replaced_and_survives_a_restart() {
        let folder = TempFolder::new("sqlite-ledger");
        let path = folder.file("kolektaku.db");
        {
            let ledger = SqliteUpdateLedger::new(Database::open(&path).unwrap());
            assert_eq!(
                ledger.seen(MediaKind::Anime, &media(1)).await.unwrap(),
                None
            );
            ledger
                .record(MediaKind::Anime, &media(1), 5.0, 10)
                .await
                .unwrap();
            ledger
                .record(MediaKind::Anime, &media(1), 6.5, 20)
                .await
                .unwrap();
        }
        let ledger = SqliteUpdateLedger::new(Database::open(&path).unwrap());
        let entry = ledger
            .seen(MediaKind::Anime, &media(1))
            .await
            .unwrap()
            .unwrap();
        assert_eq!((entry.latest, entry.checked_at), (6.5, 20));
        assert_eq!(
            ledger.seen(MediaKind::Novel, &media(1)).await.unwrap(),
            None
        );
        assert_eq!(
            ledger.seen(MediaKind::Anime, &media(2)).await.unwrap(),
            None
        );
    }
}
