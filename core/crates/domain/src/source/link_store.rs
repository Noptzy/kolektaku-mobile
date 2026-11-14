use std::future::Future;

use super::SourceLink;
use crate::error::StorageError;
use crate::media::MediaRef;

pub trait SourceLinkStore: Send + Sync {
    fn links_for(
        &self,
        media: &MediaRef,
    ) -> impl Future<Output = Result<Vec<SourceLink>, StorageError>> + Send;
    fn save_all(
        &self,
        media: &MediaRef,
        links: Vec<SourceLink>,
    ) -> impl Future<Output = Result<(), StorageError>> + Send;
    fn remove(&self, media: &MediaRef) -> impl Future<Output = Result<(), StorageError>> + Send;
}
