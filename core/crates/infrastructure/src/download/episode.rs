use std::path::PathBuf;
use std::sync::{Arc, RwLock};

use application::downloads::{CancelToken, DownloadOrder, MediaDownloader, ProgressSink};
use application::ports::{BoxFuture, Translator};
use domain::download::DownloadPhase;
use domain::error::SourceError;

use super::bytes::ByteFetcher;
use super::files::{unique_path, work_folder};
use super::hls_save::{HlsPieces, save_hls};
use super::media_plan::{MediaPlan, plan_media};
use super::session::{Session, folder_error};
use crate::http::HttpClient;

pub struct EpisodeDownloader {
    pub http: Arc<dyn HttpClient>,
    pub bytes: Arc<dyn ByteFetcher>,
    pub translator: Arc<dyn Translator>,
    output: RwLock<PathBuf>,
}

impl EpisodeDownloader {
    pub fn new(
        http: Arc<dyn HttpClient>,
        bytes: Arc<dyn ByteFetcher>,
        translator: Arc<dyn Translator>,
        output: PathBuf,
    ) -> Self {
        Self {
            http,
            bytes,
            translator,
            output: RwLock::new(output),
        }
    }

    pub fn set_output(&self, folder: PathBuf) {
        *self.output.write().unwrap() = folder;
    }

    pub fn output_folder(&self) -> Result<PathBuf, SourceError> {
        let folder = self.output.read().unwrap().clone();
        std::fs::create_dir_all(&folder).map_err(folder_error)?;
        Ok(folder)
    }

    async fn save_file(&self, session: &Session<'_>, url: &str) -> Result<String, SourceError> {
        let path = unique_path(&self.output_folder()?, &session.file_stem(), "mp4");
        let sink = session.progress.clone();
        let outcome = self
            .bytes
            .save(
                session.request(url),
                path.clone(),
                session.cancel.clone(),
                Arc::new(move |done, total| {
                    let fraction = total.map_or(0.0, |total| done as f32 / total.max(1) as f32);
                    sink(application::downloads::DownloadProgress {
                        phase: DownloadPhase::Fetching,
                        fraction: fraction * 0.99,
                        bytes: done,
                    });
                }),
            )
            .await;
        if let Err(error) = outcome {
            let _ = tokio::fs::remove_file(&path).await;
            return Err(error);
        }
        Ok(path.to_string_lossy().into_owned())
    }

    async fn run(
        &self,
        order: DownloadOrder,
        progress: ProgressSink,
        cancel: CancelToken,
    ) -> Result<String, SourceError> {
        let session = Session {
            order: &order,
            progress: &progress,
            cancel: &cancel,
        };
        session.report(DownloadPhase::Fetching, 0.0, 0);
        match plan_media(
            self.http.as_ref(),
            &order.job.stream,
            order.settings.quality,
        )
        .await?
        {
            MediaPlan::File { url } => self.save_file(&session, &url).await,
            MediaPlan::Hls {
                video,
                audio,
                resolution,
            } => {
                let work = work_folder(&self.output_folder()?, order.job.id);
                let _ = tokio::fs::remove_dir_all(&work).await;
                tokio::fs::create_dir_all(&work)
                    .await
                    .map_err(folder_error)?;
                let pieces = HlsPieces {
                    video,
                    audio,
                    resolution,
                };
                let outcome = save_hls(self, &session, pieces, &work).await;
                let _ = tokio::fs::remove_dir_all(&work).await;
                outcome
            }
        }
    }
}

impl MediaDownloader for EpisodeDownloader {
    fn download(
        &self,
        order: DownloadOrder,
        progress: ProgressSink,
        cancel: CancelToken,
    ) -> BoxFuture<'_, Result<String, SourceError>> {
        Box::pin(self.run(order, progress, cancel))
    }

    fn discard(&self, path: String) -> BoxFuture<'_, ()> {
        Box::pin(async move {
            let _ = tokio::fs::remove_file(path).await;
        })
    }
}
