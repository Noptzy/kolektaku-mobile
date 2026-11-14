use std::path::PathBuf;

use domain::error::StorageError;
use domain::media::MediaRef;
use domain::source::{SourceLink, SourceLinkStore};
use serde::{Deserialize, Serialize};

use super::JsonFile;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct LinkEntry {
    media: MediaRef,
    links: Vec<SourceLink>,
}

#[derive(Debug, Default, Serialize, Deserialize)]
#[serde(default)]
struct LinkDocument {
    entries: Vec<serde_json::Value>,
}

impl LinkDocument {
    fn typed(&self) -> Vec<LinkEntry> {
        self.entries
            .iter()
            .filter_map(|entry| serde_json::from_value(entry.clone()).ok())
            .collect()
    }

    fn replace(&mut self, entries: Vec<LinkEntry>) {
        self.entries = entries
            .into_iter()
            .filter_map(|entry| serde_json::to_value(entry).ok())
            .collect();
    }
}

pub struct JsonSourceLinkStore {
    file: JsonFile,
}

impl JsonSourceLinkStore {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self {
            file: JsonFile::new(path),
        }
    }
}

impl SourceLinkStore for JsonSourceLinkStore {
    async fn links_for(&self, media: &MediaRef) -> Result<Vec<SourceLink>, StorageError> {
        let document: LinkDocument = self.file.read().await;
        Ok(document
            .typed()
            .into_iter()
            .find(|entry| entry.media == *media)
            .map(|entry| entry.links)
            .unwrap_or_default())
    }

    async fn save_all(&self, media: &MediaRef, links: Vec<SourceLink>) -> Result<(), StorageError> {
        self.file
            .update(|document: &mut LinkDocument| {
                let mut entries = document.typed();
                entries.retain(|entry| entry.media != *media);
                entries.push(LinkEntry {
                    media: media.clone(),
                    links,
                });
                document.replace(entries);
            })
            .await
    }

    async fn remove(&self, media: &MediaRef) -> Result<(), StorageError> {
        self.file
            .update(|document: &mut LinkDocument| {
                let mut entries = document.typed();
                entries.retain(|entry| entry.media != *media);
                document.replace(entries);
            })
            .await
    }
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use domain::matching::Confidence;
    use domain::media::MediaId;
    use domain::source::{ItemId, SourceId};

    use super::*;
    use crate::storage::temp_folder::TempFolder;

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
    async fn links_are_saved_per_title_and_survive_a_restart() {
        let folder = TempFolder::new("links-restart");
        let store = JsonSourceLinkStore::new(folder.file("links.json"));
        store
            .save_all(&media(1), vec![link("a", "1"), link("b", "2")])
            .await
            .unwrap();
        store
            .save_all(&media(2), vec![link("a", "9")])
            .await
            .unwrap();
        let again = JsonSourceLinkStore::new(folder.file("links.json"));
        assert_eq!(again.links_for(&media(1)).await.unwrap().len(), 2);
        assert_eq!(
            again.links_for(&media(2)).await.unwrap()[0].item.as_str(),
            "9"
        );
        assert!(again.links_for(&media(3)).await.unwrap().is_empty());
        assert_eq!(
            again.links_for(&media(1)).await.unwrap()[0].unit_count,
            Some(12)
        );
    }

    #[tokio::test]
    async fn saving_again_replaces_the_titles_links_and_removing_forgets_them() {
        let folder = TempFolder::new("links-replace");
        let store = JsonSourceLinkStore::new(folder.file("links.json"));
        store
            .save_all(&media(1), vec![link("a", "1")])
            .await
            .unwrap();
        store
            .save_all(&media(1), vec![link("b", "2")])
            .await
            .unwrap();
        assert_eq!(
            store.links_for(&media(1)).await.unwrap()[0].source.as_str(),
            "b"
        );
        store.remove(&media(1)).await.unwrap();
        assert!(store.links_for(&media(1)).await.unwrap().is_empty());
    }

    #[tokio::test]
    async fn site_only_titles_can_have_links_and_bad_entries_are_skipped() {
        let folder = TempFolder::new("links-bad");
        let only = MediaRef::source(SourceId::new("komiku"), ItemId::new("berserk"));
        std::fs::write(
            folder.file("links.json"),
            r#"{"entries":[{"nonsense":true}]}"#,
        )
        .unwrap();
        let store = JsonSourceLinkStore::new(folder.file("links.json"));
        store
            .save_all(&only, vec![link("komiku", "berserk")])
            .await
            .unwrap();
        assert_eq!(store.links_for(&only).await.unwrap().len(), 1);
    }

    #[tokio::test]
    async fn overlapping_saves_for_different_titles_all_land() {
        let folder = TempFolder::new("links-overlap");
        let store = Arc::new(JsonSourceLinkStore::new(folder.file("links.json")));
        let mut tasks = tokio::task::JoinSet::new();
        for id in 1..=12 {
            let store = Arc::clone(&store);
            tasks.spawn(async move { store.save_all(&media(id), vec![link("a", "x")]).await });
        }
        while let Some(done) = tasks.join_next().await {
            done.unwrap().unwrap();
        }
        for id in 1..=12 {
            assert_eq!(store.links_for(&media(id)).await.unwrap().len(), 1);
        }
    }
}
