use domain::error::StorageError;
use domain::highlight::{Highlight, HighlightInput, HighlightStore};
use domain::media::MediaRef;
use rusqlite::{Connection, params};

use super::database::Database;
use super::rows::{encode, media_key};

pub struct SqliteHighlightStore {
    database: Database,
}

impl SqliteHighlightStore {
    pub fn new(database: Database) -> Self {
        Self { database }
    }
}

fn with_id(mut highlight: Highlight, id: i64) -> Highlight {
    highlight.id = id;
    highlight
}

fn insert(connection: &Connection, input: HighlightInput, now: u64) -> rusqlite::Result<i64> {
    if !input.is_storable() {
        return Ok(0);
    }
    let draft = Highlight {
        id: 0,
        entry: input.clone(),
        created_at_secs: now,
    };
    connection.execute(
        "INSERT INTO highlight(media_key, chapter, block, start, end, created_at, data) \
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        params![
            media_key(&input.media)?,
            input.chapter,
            input.block,
            input.start,
            input.end,
            now as i64,
            encode(&draft)?
        ],
    )?;
    Ok(connection.last_insert_rowid())
}

fn listed(
    connection: &Connection,
    sql: &str,
    arguments: impl rusqlite::Params,
) -> rusqlite::Result<Vec<Highlight>> {
    let mut statement = connection.prepare(sql)?;
    let rows = statement
        .query_map(arguments, |row| {
            Ok((row.get::<_, i64>(0)?, row.get::<_, String>(1)?))
        })?
        .collect::<rusqlite::Result<Vec<(i64, String)>>>()?;
    Ok(rows
        .into_iter()
        .filter_map(|(id, text)| {
            serde_json::from_str::<Highlight>(&text)
                .ok()
                .map(|found| with_id(found, id))
        })
        .collect())
}

impl HighlightStore for SqliteHighlightStore {
    async fn add(&self, input: HighlightInput, now_secs: u64) -> Result<i64, StorageError> {
        self.database
            .run(move |connection| insert(connection, input, now_secs))
            .await
    }

    async fn remove(&self, id: i64) -> Result<(), StorageError> {
        self.database
            .run(move |connection| {
                connection.execute("DELETE FROM highlight WHERE id = ?1", [id])?;
                Ok(())
            })
            .await
    }

    async fn for_chapter(
        &self,
        media: &MediaRef,
        chapter: f64,
    ) -> Result<Vec<Highlight>, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| {
                listed(
                    connection,
                    "SELECT id, data FROM highlight WHERE media_key = ?1 \
                     AND ABS(chapter - ?2) < 1e-9 ORDER BY block ASC, start ASC",
                    params![media_key(&media)?, chapter],
                )
            })
            .await
    }

    async fn all(&self) -> Result<Vec<Highlight>, StorageError> {
        self.database
            .run(|connection| {
                listed(
                    connection,
                    "SELECT id, data FROM highlight ORDER BY created_at DESC, id DESC",
                    [],
                )
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

    fn input(id: u64, chapter: f64, block: u32, start: u32) -> HighlightInput {
        HighlightInput {
            media: media(id),
            title: "Hyouka".into(),
            cover_url: None,
            chapter,
            chapter_label: format!("Chapter {chapter}"),
            block,
            start,
            end: start + 5,
            quote: "quote".into(),
            language: "en".into(),
        }
    }

    #[tokio::test]
    async fn highlights_are_listed_per_chapter_in_reading_order_and_survive_a_restart() {
        let folder = TempFolder::new("sqlite-highlights");
        let path = folder.file("kolektaku.db");
        {
            let store = SqliteHighlightStore::new(Database::open(&path).unwrap());
            store.add(input(1, 1.0, 5, 0), 10).await.unwrap();
            store.add(input(1, 1.0, 2, 8), 11).await.unwrap();
            store.add(input(1, 2.0, 0, 0), 12).await.unwrap();
        }
        let store = SqliteHighlightStore::new(Database::open(&path).unwrap());
        let first = store.for_chapter(&media(1), 1.0).await.unwrap();
        let blocks: Vec<u32> = first.iter().map(|item| item.entry.block).collect();
        assert_eq!(blocks, vec![2, 5]);
        assert!(first.iter().all(|item| item.id > 0));
        assert!(store.for_chapter(&media(9), 1.0).await.unwrap().is_empty());
    }

    #[tokio::test]
    async fn everything_is_listed_newest_first_and_removing_forgets_one() {
        let store = SqliteHighlightStore::new(Database::in_memory().unwrap());
        let one = store.add(input(1, 1.0, 0, 0), 10).await.unwrap();
        let two = store.add(input(2, 1.0, 0, 0), 20).await.unwrap();
        let all = store.all().await.unwrap();
        assert_eq!(
            all.iter().map(|item| item.id).collect::<Vec<_>>(),
            vec![two, one]
        );
        store.remove(two).await.unwrap();
        assert_eq!(store.all().await.unwrap().len(), 1);
    }

    #[tokio::test]
    async fn an_unusable_highlight_is_not_stored() {
        let store = SqliteHighlightStore::new(Database::in_memory().unwrap());
        let mut bad = input(1, 1.0, 0, 0);
        bad.end = bad.start;
        assert_eq!(store.add(bad, 1).await.unwrap(), 0);
        assert!(store.all().await.unwrap().is_empty());
    }
}
