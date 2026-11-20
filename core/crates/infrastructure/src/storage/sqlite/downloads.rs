use domain::download::{DownloadJob, DownloadLedger};
use domain::error::StorageError;
use rusqlite::params;

use super::database::Database;
use super::rows::encode;

pub struct SqliteDownloadLedger {
    database: Database,
}

impl SqliteDownloadLedger {
    pub fn new(database: Database) -> Self {
        Self { database }
    }
}

fn with_id(mut job: DownloadJob, id: i64) -> DownloadJob {
    job.id = id;
    job
}

impl DownloadLedger for SqliteDownloadLedger {
    async fn all(&self) -> Result<Vec<DownloadJob>, StorageError> {
        self.database
            .run(|connection| {
                let mut statement =
                    connection.prepare("SELECT id, data FROM download ORDER BY id")?;
                let rows = statement
                    .query_map([], |row| {
                        Ok((row.get::<_, i64>(0)?, row.get::<_, String>(1)?))
                    })?
                    .collect::<rusqlite::Result<Vec<(i64, String)>>>()?;
                Ok(rows
                    .into_iter()
                    .filter_map(|(id, text)| {
                        serde_json::from_str::<DownloadJob>(&text)
                            .ok()
                            .map(|job| with_id(job, id))
                    })
                    .collect())
            })
            .await
    }

    async fn insert(&self, job: DownloadJob) -> Result<i64, StorageError> {
        self.database
            .run(move |connection| {
                connection.execute(
                    "INSERT INTO download(created_at, data) VALUES (?1, ?2)",
                    params![job.created_at_secs as i64, encode(&job)?],
                )?;
                Ok(connection.last_insert_rowid())
            })
            .await
    }

    async fn update(&self, job: DownloadJob) -> Result<(), StorageError> {
        self.database
            .run(move |connection| {
                connection.execute(
                    "UPDATE download SET data = ?1 WHERE id = ?2",
                    params![encode(&job)?, job.id],
                )?;
                Ok(())
            })
            .await
    }

    async fn remove(&self, id: i64) -> Result<(), StorageError> {
        self.database
            .run(move |connection| {
                connection.execute("DELETE FROM download WHERE id = ?1", [id])?;
                Ok(())
            })
            .await
    }
}

#[cfg(test)]
mod tests {
    use domain::download::{DownloadPhase, DownloadTarget};
    use domain::media::{MediaId, MediaKind, MediaRef};
    use domain::stream::StreamSet;

    use super::*;

    fn job(episode: f64) -> DownloadJob {
        let target = DownloadTarget {
            media: MediaRef::catalog(MediaId::new(5).unwrap()),
            kind: MediaKind::Anime,
            title: "Judul".into(),
            episode,
            cover_url: Some("https://img.test/a.jpg".into()),
        };
        let stream = StreamSet {
            sources: Vec::new(),
            poster_url: None,
            headers: Vec::new(),
            subtitles: Vec::new(),
            skips: Vec::new(),
        };
        DownloadJob::queued(target, stream, 10)
    }

    #[tokio::test]
    async fn jobs_are_stored_with_their_new_id_updated_and_removed() {
        let ledger = SqliteDownloadLedger::new(Database::in_memory().unwrap());
        let first = ledger.insert(job(1.0)).await.unwrap();
        let second = ledger.insert(job(2.0)).await.unwrap();
        assert_ne!(first, second);
        let mut done = with_id(job(1.0), first);
        done.phase = DownloadPhase::Done;
        done.file_path = Some("/films/a.mkv".into());
        ledger.update(done.clone()).await.unwrap();
        let all = ledger.all().await.unwrap();
        assert_eq!(all.len(), 2);
        assert_eq!(all[0], done);
        assert_eq!(all[1].id, second);
        ledger.remove(first).await.unwrap();
        assert_eq!(ledger.all().await.unwrap().len(), 1);
    }
}
