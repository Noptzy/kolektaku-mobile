use std::path::PathBuf;
use std::sync::Arc;

use application::ports::Clock;
use domain::error::StorageError;
use domain::library::{
    Favorite, FavoriteInput, LibraryRepository, Progress, ProgressInput, UnitOrder,
};
use domain::media::{MediaKind, MediaRef};

use super::document::{FORMAT_VERSION, LibraryDocument};
use crate::storage::JsonFile;

const BACKUP_LABEL: &str = "before-novel";

pub struct JsonLibraryRepository {
    file: JsonFile,
    clock: Arc<dyn Clock>,
}

impl JsonLibraryRepository {
    pub fn new(path: impl Into<PathBuf>, clock: Arc<dyn Clock>) -> Self {
        Self {
            file: JsonFile::new(path),
            clock,
        }
    }

    async fn document(&self) -> LibraryDocument {
        self.file.read().await
    }

    async fn change<R>(
        &self,
        change: impl FnOnce(&mut LibraryDocument) -> R,
    ) -> Result<R, StorageError> {
        self.file
            .update(|document: &mut LibraryDocument| {
                document.version = FORMAT_VERSION;
                change(document)
            })
            .await
    }
}

impl LibraryRepository for JsonLibraryRepository {
    async fn favorites(&self, kind: MediaKind) -> Result<Vec<Favorite>, StorageError> {
        Ok(self.document().await.favorites_of(kind))
    }

    async fn is_favorite(&self, kind: MediaKind, media: &MediaRef) -> Result<bool, StorageError> {
        Ok(self.document().await.is_favorite(kind, media))
    }

    async fn toggle_favorite(&self, favorite: FavoriteInput) -> Result<bool, StorageError> {
        let now = self.clock.now_secs();
        self.change(|document| document.toggle_favorite(favorite, now))
            .await
    }

    async fn history(&self, kind: MediaKind) -> Result<Vec<Progress>, StorageError> {
        Ok(self.document().await.history_of(kind))
    }

    async fn save_progress(&self, progress: ProgressInput) -> Result<(), StorageError> {
        self.change(|document| document.save_progress(progress))
            .await
    }

    async fn progress_for(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Result<Option<Progress>, StorageError> {
        Ok(self.document().await.progress_for(kind, media, unit_number))
    }

    async fn last_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<Option<Progress>, StorageError> {
        Ok(self.document().await.last_progress(kind, media))
    }

    async fn remove_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Result<(), StorageError> {
        self.change(|document| document.remove_progress(kind, media, unit_number))
            .await
    }

    async fn clear_history(&self, kind: MediaKind) -> Result<(), StorageError> {
        self.change(|document| document.clear_history(kind)).await
    }

    async fn unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<UnitOrder, StorageError> {
        Ok(self.document().await.unit_order_of(kind, media))
    }

    async fn set_unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        order: UnitOrder,
    ) -> Result<(), StorageError> {
        self.change(|document| document.set_unit_order(kind, media, order))
            .await
    }

    async fn preference(&self, name: &str) -> Result<Option<String>, StorageError> {
        Ok(self.document().await.preference_of(name))
    }

    async fn set_preference(&self, name: &str, value: &str) -> Result<(), StorageError> {
        self.change(|document| document.set_preference(name, value))
            .await
    }

    async fn searches(&self, kind: MediaKind) -> Result<Vec<String>, StorageError> {
        Ok(self.document().await.searches_of(kind))
    }

    async fn add_search(&self, kind: MediaKind, query: &str) -> Result<(), StorageError> {
        self.change(|document| document.add_search(kind, query))
            .await
    }

    async fn clear_searches(&self, kind: MediaKind) -> Result<(), StorageError> {
        self.change(|document| document.clear_searches(kind)).await
    }

    async fn move_entries(
        &self,
        from: MediaKind,
        to: MediaKind,
        media: &[MediaRef],
    ) -> Result<usize, StorageError> {
        if self.document().await.movable(from, media) == 0 {
            return Ok(0);
        }
        self.file.keep_copy(BACKUP_LABEL).await?;
        self.change(|document| document.move_entries(from, to, media))
            .await
    }
}
