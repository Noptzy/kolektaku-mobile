use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};

use domain::download::{DownloadJob, DownloadLedger, DownloadPhase, DownloadTarget};
use domain::error::{SourceError, StorageError};
use domain::settings::TranslationLanguage;
use domain::stream::StreamSet;

use super::board::JobBoard;
use super::cancel::CancelToken;
use super::port::{DownloadOrder, MediaDownloader, ProgressSink};
use super::settings_store::DownloadSettingsStore;
use crate::ports::Clock;

pub type LanguageSource = Arc<dyn Fn() -> TranslationLanguage + Send + Sync>;

pub struct DownloadQueue<L: DownloadLedger> {
    pub(super) ledger: Arc<L>,
    pub(super) downloader: Arc<dyn MediaDownloader>,
    clock: Arc<dyn Clock>,
    settings: Arc<DownloadSettingsStore>,
    language: LanguageSource,
    pub(super) board: Mutex<JobBoard>,
    running: Mutex<Option<(i64, CancelToken)>>,
    working: AtomicBool,
}

impl<L: DownloadLedger + 'static> DownloadQueue<L> {
    pub async fn load(
        ledger: Arc<L>,
        downloader: Arc<dyn MediaDownloader>,
        clock: Arc<dyn Clock>,
        settings: Arc<DownloadSettingsStore>,
        language: LanguageSource,
    ) -> Arc<Self> {
        let saved = ledger.all().await.unwrap_or_default();
        let (board, interrupted) = JobBoard::from_saved(saved);
        for job in interrupted {
            let _ = ledger.update(job).await;
        }
        Arc::new(Self {
            ledger,
            downloader,
            clock,
            settings,
            language,
            board: Mutex::new(board),
            running: Mutex::new(None),
            working: AtomicBool::new(false),
        })
    }

    pub fn settings(&self) -> &Arc<DownloadSettingsStore> {
        &self.settings
    }

    pub fn snapshot(&self) -> Vec<DownloadJob> {
        self.board.lock().unwrap().list()
    }

    pub async fn enqueue(
        self: &Arc<Self>,
        target: DownloadTarget,
        stream: StreamSet,
    ) -> Result<DownloadJob, StorageError> {
        let known = self.board.lock().unwrap().for_episode(&target);
        if let Some(job) = known {
            if job.phase.can_retry() {
                return self.restart(job, stream).await;
            }
            return Ok(job);
        }
        let mut job = DownloadJob::queued(target, stream, self.clock.now_secs());
        job.id = self.ledger.insert(job.clone()).await?;
        self.board.lock().unwrap().put(job.clone());
        self.wake();
        Ok(job)
    }

    pub async fn retry(
        self: &Arc<Self>,
        id: i64,
        stream: StreamSet,
    ) -> Result<Option<DownloadJob>, StorageError> {
        let Some(job) = self.board.lock().unwrap().get(id) else {
            return Ok(None);
        };
        if !job.phase.can_retry() {
            return Ok(Some(job));
        }
        self.restart(job, stream).await.map(Some)
    }

    async fn restart(
        self: &Arc<Self>,
        job: DownloadJob,
        stream: StreamSet,
    ) -> Result<DownloadJob, StorageError> {
        let job = job.restarted(stream);
        self.ledger.update(job.clone()).await?;
        self.board.lock().unwrap().put(job.clone());
        self.wake();
        Ok(job)
    }

    pub async fn cancel(&self, id: i64) -> Result<(), StorageError> {
        if let Some((running, token)) = self.running.lock().unwrap().as_ref()
            && *running == id
        {
            token.cancel();
            return Ok(());
        }
        let Some(mut job) = self.board.lock().unwrap().get(id) else {
            return Ok(());
        };
        if job.phase == DownloadPhase::Queued {
            job.phase = DownloadPhase::Cancelled;
            self.board.lock().unwrap().put(job.clone());
            self.ledger.update(job).await?;
        }
        Ok(())
    }

    fn wake(self: &Arc<Self>) {
        if self.working.swap(true, Ordering::SeqCst) {
            return;
        }
        let queue = Arc::clone(self);
        tokio::spawn(async move { queue.work().await });
    }

    async fn work(self: Arc<Self>) {
        loop {
            let next = self.board.lock().unwrap().next_queued();
            match next {
                Some(job) => self.run(job).await,
                None => {
                    self.working.store(false, Ordering::SeqCst);
                    let late = self.board.lock().unwrap().next_queued().is_some();
                    if !late || self.working.swap(true, Ordering::SeqCst) {
                        return;
                    }
                }
            }
        }
    }

    async fn run(self: &Arc<Self>, job: DownloadJob) {
        let token = CancelToken::default();
        *self.running.lock().unwrap() = Some((job.id, token.clone()));
        let queue = Arc::clone(self);
        let id = job.id;
        let progress: ProgressSink =
            Arc::new(move |step| queue.board.lock().unwrap().progress(id, step));
        let order = DownloadOrder {
            job,
            settings: self.settings.get(),
            language: (self.language)(),
        };
        let outcome = self
            .downloader
            .download(order, progress, token.clone())
            .await;
        *self.running.lock().unwrap() = None;
        self.settle(id, outcome, token.is_cancelled()).await;
    }

    async fn settle(&self, id: i64, outcome: Result<String, SourceError>, cancelled: bool) {
        let Some(mut job) = self.board.lock().unwrap().get(id) else {
            return;
        };
        match outcome {
            Ok(path) => {
                job.phase = DownloadPhase::Done;
                job.progress = 1.0;
                job.file_path = Some(path);
            }
            Err(_) if cancelled => job.phase = DownloadPhase::Cancelled,
            Err(error) => {
                job.phase = DownloadPhase::Failed;
                job.error = Some(error.to_string());
            }
        }
        self.board.lock().unwrap().put(job.clone());
        let _ = self.ledger.update(job).await;
    }
}
