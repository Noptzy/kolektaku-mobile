use std::collections::HashMap;
use std::sync::Mutex;

use domain::error::StorageError;
use domain::media::MediaRef;
use domain::source::{SourceLink, SourceLinkStore};

#[derive(Default)]
pub struct MemoryLinkStore {
    links: Mutex<HashMap<MediaRef, Vec<SourceLink>>>,
}

impl MemoryLinkStore {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn snapshot(&self, media: &MediaRef) -> Vec<SourceLink> {
        self.links
            .lock()
            .unwrap()
            .get(media)
            .cloned()
            .unwrap_or_default()
    }
}

impl SourceLinkStore for MemoryLinkStore {
    async fn links_for(&self, media: &MediaRef) -> Result<Vec<SourceLink>, StorageError> {
        Ok(self.snapshot(media))
    }

    async fn save_all(&self, media: &MediaRef, links: Vec<SourceLink>) -> Result<(), StorageError> {
        self.links.lock().unwrap().insert(media.clone(), links);
        Ok(())
    }

    async fn remove(&self, media: &MediaRef) -> Result<(), StorageError> {
        self.links.lock().unwrap().remove(media);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use domain::matching::Confidence;
    use domain::media::MediaId;
    use domain::source::{ItemId, SourceId};

    fn link() -> SourceLink {
        SourceLink::matched(
            SourceId::new("a"),
            ItemId::new("1"),
            Confidence::new(0.9),
            1,
        )
    }

    #[tokio::test]
    async fn saved_links_can_be_read_back_and_removed() {
        let store = MemoryLinkStore::new();
        let media = MediaRef::catalog(MediaId::new(1).unwrap());
        assert!(store.links_for(&media).await.unwrap().is_empty());
        store.save_all(&media, vec![link()]).await.unwrap();
        assert_eq!(store.links_for(&media).await.unwrap(), vec![link()]);
        store.remove(&media).await.unwrap();
        assert!(store.links_for(&media).await.unwrap().is_empty());
    }

    #[tokio::test]
    async fn links_are_kept_per_media() {
        let store = MemoryLinkStore::new();
        let first = MediaRef::catalog(MediaId::new(1).unwrap());
        let second = MediaRef::catalog(MediaId::new(2).unwrap());
        store.save_all(&first, vec![link()]).await.unwrap();
        assert!(store.links_for(&second).await.unwrap().is_empty());
    }
}
