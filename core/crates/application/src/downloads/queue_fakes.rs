use std::sync::{Arc, Mutex};
use std::time::Duration;

use domain::download::{DownloadJob, DownloadLedger, DownloadPhase, DownloadTarget};
use domain::error::{SourceError, StorageError};
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::settings::TranslationLanguage;
use domain::stream::StreamSet;
use tokio::sync::Notify;

use super::cancel::CancelToken;
use super::port::{DownloadOrder, DownloadProgress, MediaDownloader, ProgressSink};
use super::queue::DownloadQueue;
use super::settings_store::DownloadSettingsStore;
use crate::ports::BoxFuture;
use crate::testing::FakeClock;

#[derive(Default)]
pub struct MemoryLedger {
    pub rows: Mutex<Vec<DownloadJob>>,
}

impl DownloadLedger for MemoryLedger {
    async fn all(&self) -> Result<Vec<DownloadJob>, StorageError> {
        Ok(self.rows.lock().unwrap().clone())
    }

    async fn insert(&self, mut job: DownloadJob) -> Result<i64, StorageError> {
        let mut rows = self.rows.lock().unwrap();
        job.id = rows.len() as i64 + 1;
        rows.push(job.clone());
        Ok(job.id)
    }

    async fn update(&self, job: DownloadJob) -> Result<(), StorageError> {
        let mut rows = self.rows.lock().unwrap();
        if let Some(row) = rows.iter_mut().find(|row| row.id == job.id) {
            *row = job;
        }
        Ok(())
    }

    async fn remove(&self, id: i64) -> Result<(), StorageError> {
        self.rows.lock().unwrap().retain(|row| row.id != id);
        Ok(())
    }
}

#[derive(Default)]
pub struct FakeDownloader {
    pub orders: Mutex<Vec<DownloadOrder>>,
    pub failing: Mutex<bool>,
    pub hold: Mutex<Option<Arc<Notify>>>,
    pub discarded: Mutex<Vec<String>>,
}

impl MediaDownloader for FakeDownloader {
    fn download(
        &self,
        order: DownloadOrder,
        progress: ProgressSink,
        cancel: CancelToken,
    ) -> BoxFuture<'_, Result<String, SourceError>> {
        Box::pin(async move {
            let id = order.job.id;
            self.orders.lock().unwrap().push(order);
            progress(DownloadProgress {
                phase: DownloadPhase::Fetching,
                fraction: 0.5,
                bytes: 10,
            });
            let hold = self.hold.lock().unwrap().clone();
            if let Some(gate) = hold {
                gate.notified().await;
            }
            if cancel.is_cancelled() {
                return Err(SourceError::Unavailable("stopped".into()));
            }
            if *self.failing.lock().unwrap() {
                return Err(SourceError::Network("offline".into()));
            }
            Ok(format!("/films/{id}.mkv"))
        })
    }

    fn discard(&self, path: String) -> BoxFuture<'_, ()> {
        Box::pin(async move { self.discarded.lock().unwrap().push(path) })
    }
}

pub fn target(episode: f64) -> DownloadTarget {
    DownloadTarget {
        media: MediaRef::catalog(MediaId::new(7).unwrap()),
        kind: MediaKind::Anime,
        title: "Judul".into(),
        episode,
        cover_url: None,
    }
}

pub fn stream() -> StreamSet {
    StreamSet {
        sources: Vec::new(),
        poster_url: None,
        headers: Vec::new(),
        subtitles: Vec::new(),
        skips: Vec::new(),
    }
}

pub async fn queue_with(
    ledger: Arc<MemoryLedger>,
    downloader: Arc<FakeDownloader>,
) -> Arc<DownloadQueue<MemoryLedger>> {
    DownloadQueue::load(
        ledger,
        downloader,
        Arc::new(FakeClock::at(100)),
        DownloadSettingsStore::holding(Default::default()),
        Arc::new(|| TranslationLanguage::Indonesian),
    )
    .await
}

pub async fn settled(queue: &DownloadQueue<MemoryLedger>, id: i64) -> DownloadJob {
    for _ in 0..200 {
        let job = queue
            .snapshot()
            .into_iter()
            .find(|job| job.id == id)
            .unwrap();
        if !job.phase.is_active() {
            return job;
        }
        tokio::time::sleep(Duration::from_millis(5)).await;
    }
    panic!("the download never finished");
}
