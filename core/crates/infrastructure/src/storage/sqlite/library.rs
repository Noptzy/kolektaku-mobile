use std::path::Path;
use std::sync::Arc;

use application::ports::Clock;
use domain::error::StorageError;
use domain::library::{
    Favorite, FavoriteInput, LibraryRepository, Progress, ProgressInput, UnitOrder,
};
use domain::media::{MediaKind, MediaRef};

use super::database::Database;
use super::{favorites, history, move_rows, preferences};

pub struct SqliteLibraryRepository {
    database: Database,
    clock: Arc<dyn Clock>,
}

impl SqliteLibraryRepository {
    pub fn new(database: Database, clock: Arc<dyn Clock>) -> Self {
        Self { database, clock }
    }

    pub fn open(path: &Path, clock: Arc<dyn Clock>) -> Result<Self, StorageError> {
        Ok(Self::new(Database::open(path)?, clock))
    }

    pub fn database(&self) -> &Database {
        &self.database
    }
}

impl LibraryRepository for SqliteLibraryRepository {
    async fn favorites(&self, kind: MediaKind) -> Result<Vec<Favorite>, StorageError> {
        self.database
            .run(move |connection| favorites::list(connection, kind))
            .await
    }

    async fn is_favorite(&self, kind: MediaKind, media: &MediaRef) -> Result<bool, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| favorites::exists(connection, kind, &media))
            .await
    }

    async fn toggle_favorite(&self, favorite: FavoriteInput) -> Result<bool, StorageError> {
        let now = self.clock.now_secs();
        self.database
            .run(move |connection| favorites::toggle(connection, favorite, now))
            .await
    }

    async fn history(&self, kind: MediaKind) -> Result<Vec<Progress>, StorageError> {
        self.database
            .run(move |connection| history::list(connection, kind))
            .await
    }

    async fn save_progress(&self, progress: ProgressInput) -> Result<(), StorageError> {
        self.database
            .run(move |connection| history::save(connection, progress))
            .await
    }

    async fn progress_for(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Result<Option<Progress>, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| history::find(connection, kind, &media, unit_number))
            .await
    }

    async fn last_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<Option<Progress>, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| history::last(connection, kind, &media))
            .await
    }

    async fn remove_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Result<(), StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| history::remove(connection, kind, &media, unit_number))
            .await
    }

    async fn clear_history(&self, kind: MediaKind) -> Result<(), StorageError> {
        self.database
            .run(move |connection| history::clear(connection, kind))
            .await
    }

    async fn unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<UnitOrder, StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| preferences::unit_order(connection, kind, &media))
            .await
    }

    async fn set_unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        order: UnitOrder,
    ) -> Result<(), StorageError> {
        let media = media.clone();
        self.database
            .run(move |connection| preferences::set_unit_order(connection, kind, &media, order))
            .await
    }

    async fn preference(&self, name: &str) -> Result<Option<String>, StorageError> {
        let name = name.to_string();
        self.database
            .run(move |connection| preferences::preference(connection, &name))
            .await
    }

    async fn set_preference(&self, name: &str, value: &str) -> Result<(), StorageError> {
        let (name, value) = (name.to_string(), value.to_string());
        self.database
            .run(move |connection| preferences::set_preference(connection, &name, &value))
            .await
    }

    async fn searches(&self, kind: MediaKind) -> Result<Vec<String>, StorageError> {
        self.database
            .run(move |connection| preferences::searches(connection, kind))
            .await
    }

    async fn add_search(&self, kind: MediaKind, query: &str) -> Result<(), StorageError> {
        let query = query.to_string();
        self.database
            .run(move |connection| preferences::add_search(connection, kind, &query))
            .await
    }

    async fn clear_searches(&self, kind: MediaKind) -> Result<(), StorageError> {
        self.database
            .run(move |connection| preferences::clear_searches(connection, kind))
            .await
    }

    async fn move_entries(
        &self,
        from: MediaKind,
        to: MediaKind,
        media: &[MediaRef],
    ) -> Result<usize, StorageError> {
        let media = media.to_vec();
        self.database
            .run(move |connection| move_rows::move_entries(connection, from, to, &media))
            .await
    }
}
