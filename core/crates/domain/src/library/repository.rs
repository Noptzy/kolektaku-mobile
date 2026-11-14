use std::future::Future;

use super::{Favorite, FavoriteInput, Progress, ProgressInput, UnitOrder};
use crate::error::StorageError;
use crate::media::{MediaKind, MediaRef};

pub trait LibraryRepository: Send + Sync {
    fn favorites(
        &self,
        kind: MediaKind,
    ) -> impl Future<Output = Result<Vec<Favorite>, StorageError>> + Send;
    fn is_favorite(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> impl Future<Output = Result<bool, StorageError>> + Send;
    fn toggle_favorite(
        &self,
        favorite: FavoriteInput,
    ) -> impl Future<Output = Result<bool, StorageError>> + Send;

    fn history(
        &self,
        kind: MediaKind,
    ) -> impl Future<Output = Result<Vec<Progress>, StorageError>> + Send;
    fn save_progress(
        &self,
        progress: ProgressInput,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;
    fn progress_for(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> impl Future<Output = Result<Option<Progress>, StorageError>> + Send;
    fn last_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> impl Future<Output = Result<Option<Progress>, StorageError>> + Send;
    fn remove_progress(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        unit_number: f64,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;
    fn clear_history(
        &self,
        kind: MediaKind,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;

    fn unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
    ) -> impl Future<Output = Result<UnitOrder, StorageError>> + Send;
    fn set_unit_order(
        &self,
        kind: MediaKind,
        media: &MediaRef,
        order: UnitOrder,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;

    fn preference(
        &self,
        name: &str,
    ) -> impl Future<Output = Result<Option<String>, StorageError>> + Send;
    fn set_preference(
        &self,
        name: &str,
        value: &str,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;

    fn searches(
        &self,
        kind: MediaKind,
    ) -> impl Future<Output = Result<Vec<String>, StorageError>> + Send;
    fn add_search(
        &self,
        kind: MediaKind,
        query: &str,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;
    fn clear_searches(
        &self,
        kind: MediaKind,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;
}
