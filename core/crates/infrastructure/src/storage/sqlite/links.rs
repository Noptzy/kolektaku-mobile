use domain::error::StorageError;
use domain::media::MediaRef;
use domain::source::{SourceLink, SourceLinkStore};
use rusqlite::{Connection, Transaction, params};

use super::database::Database;
use super::rows::{decode_all, encode, media_key};

pub struct SqliteSourceLinkStore {
    database: Database,
}

impl SqliteSourceLinkStore {
    pub fn new(database: Database) -> Self {
        Self { database }
    }
}

fn read(connection: &Connection, media: &MediaRef) -> rusqlite::Result<Vec<SourceLink>> {
    let mut statement = connection
        .prepare("SELECT data FROM source_link WHERE media_key = ?1 ORDER BY position ASC")?;
    let rows = statement
        .query_map([media_key(media)?], |row| row.get::<_, String>(0))?
        .collect::<rusqlite::Result<Vec<String>>>()?;
    Ok(decode_all(rows))
}

pub fn put_links(
    transaction: &Transaction,
    media: &MediaRef,
    links: &[SourceLink],
) -> rusqlite::Result<()> {
    let key = media_key(media)?;
    transaction.execute("DELETE FROM source_link WHERE media_key = ?1", [&key])?;
    for (position, link) in links.iter().enumerate() {
        transaction.execute(
            "INSERT OR REPLACE INTO source_link(media_key, source, position, data) \
             VALUES (?1, ?2, ?3, ?4)",
            params![key, link.source.as_str(), position as i64, encode(link)?],
        )?;
    }
    Ok(())
}

pub fn replace_links(
    connection: &mut Connection,
    media: &MediaRef,
    links: &[SourceLink],
) -> rusqlite::Result<()> {
    let transaction = connection.transaction()?;
    put_links(&transaction, media, links)?;
    transaction.commit()
}

impl SourceLinkStore for SqliteSourceLinkStore {
    async fn links_for(&self, media: &MediaRef) -> Result<Vec<SourceLink>, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| read(connection, &media))
            .await
    }

    async fn save_all(&self, media: &MediaRef, links: Vec<SourceLink>) -> Result<(), StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| replace_links(connection, &media, &links))
            .await
    }

    async fn remove(&self, media: &MediaRef) -> Result<(), StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| replace_links(connection, &media, &[]))
            .await
    }
}

#[cfg(test)]
mod tests {
    use domain::matching::Confidence;
    use domain::media::MediaId;
    use domain::source::{ItemId, LinkVariant, SourceId};

    use super::*;
    use crate::storage::TempFolder;

    fn media(id: u64) -> MediaRef {
        MediaRef::catalog(MediaId::new(id).unwrap())
    }

    fn link(source: &str, item: &str) -> SourceLink {
        SourceLink::matched(
            SourceId::new(source),
            ItemId::new(item),
            Confidence::new(0.9),
            7,
        )
        .with_unit_count(Some(12))
    }

    #[tokio::test]
    async fn links_are_saved_per_title_in_order_and_survive_a_restart() {
        let folder = TempFolder::new("sqlite-links");
        let path = folder.file("kolektaku.db");
        {
            let store = SqliteSourceLinkStore::new(Database::open(&path).unwrap());
            let dubbed = link("a", "1")
                .with_variants(vec![LinkVariant::new(
                    ItemId::new("1-dub"),
                    "Dub Indonesia",
                )])
                .with_title("Kimetsu no Yaiba")
                .with_matcher_version(2);
            store
                .save_all(&media(1), vec![dubbed, link("b", "2")])
                .await
                .unwrap();
            store
                .save_all(&media(2), vec![link("a", "9")])
                .await
                .unwrap();
        }
        let store = SqliteSourceLinkStore::new(Database::open(&path).unwrap());
        let first = store.links_for(&media(1)).await.unwrap();
        let sources: Vec<&str> = first.iter().map(|item| item.source.as_str()).collect();
        assert_eq!(sources, vec!["a", "b"]);
        assert_eq!(first[0].variants[0].audio, "Dub Indonesia");
        assert_eq!(first[0].title.as_deref(), Some("Kimetsu no Yaiba"));
        assert_eq!(first[0].matcher_version, 2);
        assert_eq!(first[0].unit_count, Some(12));
        assert_eq!(
            store.links_for(&media(2)).await.unwrap()[0].item.as_str(),
            "9"
        );
        assert!(store.links_for(&media(3)).await.unwrap().is_empty());
    }

    #[tokio::test]
    async fn saving_again_replaces_the_titles_links_and_removing_forgets_them() {
        let store = SqliteSourceLinkStore::new(Database::in_memory().unwrap());
        store
            .save_all(&media(1), vec![link("a", "1"), link("b", "2")])
            .await
            .unwrap();
        store
            .save_all(&media(1), vec![link("c", "3")])
            .await
            .unwrap();
        let now = store.links_for(&media(1)).await.unwrap();
        assert_eq!(now.len(), 1);
        assert_eq!(now[0].source.as_str(), "c");
        store.remove(&media(1)).await.unwrap();
        assert!(store.links_for(&media(1)).await.unwrap().is_empty());
    }

    #[tokio::test]
    async fn one_link_per_source_even_if_given_twice() {
        let store = SqliteSourceLinkStore::new(Database::in_memory().unwrap());
        store
            .save_all(&media(1), vec![link("a", "1"), link("a", "2")])
            .await
            .unwrap();
        let found = store.links_for(&media(1)).await.unwrap();
        assert_eq!(found.len(), 1);
        assert_eq!(found[0].item.as_str(), "2");
    }
}
