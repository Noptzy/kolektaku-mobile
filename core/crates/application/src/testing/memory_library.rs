use std::sync::Mutex;

use domain::error::StorageError;
use domain::library::{
    Favorite, FavoriteInput, LibraryRepository, Progress, ProgressInput, UnitOrder,
};
use domain::media::{MediaKind, MediaRef};

use super::memory_state::{State, same_entry};

#[derive(Default)]
pub struct MemoryLibrary {
    state: Mutex<State>,
}

impl MemoryLibrary {
    pub fn new() -> Self {
        Self::default()
    }
}

impl LibraryRepository for MemoryLibrary {
    async fn favorites(&self, kind: MediaKind) -> Result<Vec<Favorite>, StorageError> {
        let state = self.state.lock().unwrap();
        Ok(state
            .favorites
            .iter()
            .filter(|item| item.entry.kind == kind)
            .cloned()
            .collect())
    }

    async fn is_favorite(&self, kind: MediaKind, media: &MediaRef) -> Result<bool, StorageError> {
        let state = self.state.lock().unwrap();
        Ok(state
            .favorites
            .iter()
            .any(|item| item.entry.kind == kind && item.entry.media == *media))
    }

    async fn toggle_favorite(&self, favorite: FavoriteInput) -> Result<bool, StorageError> {
        let mut state = self.state.lock().unwrap();
        let before = state.favorites.len();
        state.favorites.retain(|item| {
            !(item.entry.kind == favorite.kind && item.entry.media == favorite.media)
        });
        if state.favorites.len() < before {
            return Ok(false);
        }
        state.favorites.insert(0, Favorite::added(favorite, 0));
        Ok(true)
    }

    async fn history(&self, kind: MediaKind) -> Result<Vec<Progress>, StorageError> {
        let state = self.state.lock().unwrap();
        let mut found: Vec<Progress> = state
            .history
            .iter()
            .filter(|item| item.entry.kind == kind)
            .cloned()
            .collect();
        found.sort_by_key(|item| std::cmp::Reverse(item.entry.updated_at_secs));
        Ok(found)
    }

    async fn save_progress(&self, progress: ProgressInput) -> Result<(), StorageError> {
        let mut state = self.state.lock().unwrap();
        let (kind, media, unit) = (progress.kind, progress.media.clone(), progress.unit_number);
        state
            .history
            .retain(|item| !same_entry(item, kind, &media, unit));
        state.history.push(Progress::from_input(progress));
        Ok(())
    }

    async fn progress_for(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Result<Option<Progress>, StorageError> {
        let state = self.state.lock().unwrap();
        Ok(state
            .history
            .iter()
            .find(|item| same_entry(item, kind, media, unit_number))
            .cloned())
    }

    async fn last_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<Option<Progress>, StorageError> {
        let state = self.state.lock().unwrap();
        Ok(state
            .history
            .iter()
            .filter(|item| item.entry.kind == kind && item.entry.media == *media)
            .max_by_key(|item| item.entry.updated_at_secs)
            .cloned())
    }

    async fn remove_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> Result<(), StorageError> {
        self.state
            .lock()
            .unwrap()
            .history
            .retain(|item| !same_entry(item, kind, media, unit_number));
        Ok(())
    }

    async fn clear_history(&self, kind: MediaKind) -> Result<(), StorageError> {
        self.state
            .lock()
            .unwrap()
            .history
            .retain(|item| item.entry.kind != kind);
        Ok(())
    }

    async fn unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> Result<UnitOrder, StorageError> {
        let state = self.state.lock().unwrap();
        Ok(state
            .orders
            .get(&(kind, media.clone()))
            .copied()
            .unwrap_or_default())
    }

    async fn set_unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        order: UnitOrder,
    ) -> Result<(), StorageError> {
        self.state
            .lock()
            .unwrap()
            .orders
            .insert((kind, media.clone()), order);
        Ok(())
    }

    async fn preference(&self, name: &str) -> Result<Option<String>, StorageError> {
        Ok(self.state.lock().unwrap().preferences.get(name).cloned())
    }

    async fn set_preference(&self, name: &str, value: &str) -> Result<(), StorageError> {
        self.state
            .lock()
            .unwrap()
            .preferences
            .insert(name.into(), value.into());
        Ok(())
    }

    async fn searches(&self, kind: MediaKind) -> Result<Vec<String>, StorageError> {
        Ok(self
            .state
            .lock()
            .unwrap()
            .searches
            .get(&kind)
            .cloned()
            .unwrap_or_default())
    }

    async fn add_search(&self, kind: MediaKind, query: &str) -> Result<(), StorageError> {
        let mut state = self.state.lock().unwrap();
        let recent = state.searches.entry(kind).or_default();
        recent.retain(|known| known != query);
        recent.insert(0, query.to_string());
        Ok(())
    }

    async fn clear_searches(&self, kind: MediaKind) -> Result<(), StorageError> {
        self.state.lock().unwrap().searches.remove(&kind);
        Ok(())
    }
}
