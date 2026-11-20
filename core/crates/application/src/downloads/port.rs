use std::sync::Arc;

use domain::download::{DownloadJob, DownloadPhase, DownloadSettings};
use domain::error::SourceError;
use domain::settings::TranslationLanguage;

use super::cancel::CancelToken;
use crate::ports::BoxFuture;

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct DownloadProgress {
    pub phase: DownloadPhase,
    pub fraction: f32,
    pub bytes: u64,
}

pub type ProgressSink = Arc<dyn Fn(DownloadProgress) + Send + Sync>;

#[derive(Debug, Clone, PartialEq)]
pub struct DownloadOrder {
    pub job: DownloadJob,
    pub settings: DownloadSettings,
    pub language: TranslationLanguage,
}

pub trait MediaDownloader: Send + Sync {
    fn download(
        &self,
        order: DownloadOrder,
        progress: ProgressSink,
        cancel: CancelToken,
    ) -> BoxFuture<'_, Result<String, SourceError>>;

    fn discard(&self, path: String) -> BoxFuture<'_, ()>;
}
