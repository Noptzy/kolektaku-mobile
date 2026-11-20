use std::sync::Arc;
use std::time::Duration;

use domain::download::{DownloadJob, DownloadPhase};
use tokio::sync::Notify;

use super::board::INTERRUPTED;
use super::queue_fakes::{FakeDownloader, MemoryLedger, queue_with, settled, stream, target};

#[tokio::test]
async fn a_queued_episode_is_downloaded_and_remembered_as_done() {
    let ledger = Arc::new(MemoryLedger::default());
    let downloader = Arc::new(FakeDownloader::default());
    let queue = queue_with(ledger.clone(), downloader.clone()).await;
    let job = queue.enqueue(target(1.0), stream()).await.unwrap();
    let done = settled(&queue, job.id).await;
    assert_eq!(done.phase, DownloadPhase::Done);
    assert_eq!(done.file_path.as_deref(), Some("/films/1.mkv"));
    assert_eq!(ledger.rows.lock().unwrap()[0].phase, DownloadPhase::Done);
    assert_eq!(downloader.orders.lock().unwrap()[0].job.target.episode, 1.0);
}

#[tokio::test]
async fn asking_for_the_same_episode_twice_downloads_it_once() {
    let downloader = Arc::new(FakeDownloader::default());
    let queue = queue_with(Arc::new(MemoryLedger::default()), downloader.clone()).await;
    let first = queue.enqueue(target(2.0), stream()).await.unwrap();
    let second = queue.enqueue(target(2.0), stream()).await.unwrap();
    assert_eq!(first.id, second.id);
    settled(&queue, first.id).await;
    assert_eq!(downloader.orders.lock().unwrap().len(), 1);
}

#[tokio::test]
async fn a_batch_runs_one_after_another_in_order() {
    let downloader = Arc::new(FakeDownloader::default());
    let queue = queue_with(Arc::new(MemoryLedger::default()), downloader.clone()).await;
    let mut ids = Vec::new();
    for episode in 1..=3 {
        ids.push(
            queue
                .enqueue(target(f64::from(episode)), stream())
                .await
                .unwrap()
                .id,
        );
    }
    for id in &ids {
        settled(&queue, *id).await;
    }
    let order: Vec<f64> = downloader
        .orders
        .lock()
        .unwrap()
        .iter()
        .map(|o| o.job.target.episode)
        .collect();
    assert_eq!(order, vec![1.0, 2.0, 3.0]);
}

#[tokio::test]
async fn a_failed_download_keeps_the_reason_and_can_be_retried() {
    let downloader = Arc::new(FakeDownloader::default());
    *downloader.failing.lock().unwrap() = true;
    let queue = queue_with(Arc::new(MemoryLedger::default()), downloader.clone()).await;
    let job = queue.enqueue(target(3.0), stream()).await.unwrap();
    let failed = settled(&queue, job.id).await;
    assert_eq!(failed.phase, DownloadPhase::Failed);
    assert!(failed.error.unwrap().contains("offline"));
    *downloader.failing.lock().unwrap() = false;
    queue.retry(job.id, stream()).await.unwrap();
    assert_eq!(settled(&queue, job.id).await.phase, DownloadPhase::Done);
}

#[tokio::test]
async fn cancelling_a_running_download_stops_it() {
    let downloader = Arc::new(FakeDownloader::default());
    let gate = Arc::new(Notify::new());
    *downloader.hold.lock().unwrap() = Some(gate.clone());
    let queue = queue_with(Arc::new(MemoryLedger::default()), downloader.clone()).await;
    let job = queue.enqueue(target(4.0), stream()).await.unwrap();
    while downloader.orders.lock().unwrap().is_empty() {
        tokio::time::sleep(Duration::from_millis(2)).await;
    }
    let running = queue.snapshot()[0].clone();
    assert_eq!(
        (running.phase, running.progress),
        (DownloadPhase::Fetching, 0.5)
    );
    queue.cancel(job.id).await.unwrap();
    gate.notify_one();
    assert_eq!(
        settled(&queue, job.id).await.phase,
        DownloadPhase::Cancelled
    );
}

#[tokio::test]
async fn a_download_cut_off_by_a_restart_comes_back_as_failed() {
    let ledger = Arc::new(MemoryLedger::default());
    let mut cut = DownloadJob::queued(target(5.0), stream(), 1);
    cut.id = 1;
    cut.phase = DownloadPhase::Muxing;
    ledger.rows.lock().unwrap().push(cut);
    let queue = queue_with(ledger.clone(), Arc::new(FakeDownloader::default())).await;
    let job = queue.snapshot()[0].clone();
    assert_eq!(job.phase, DownloadPhase::Failed);
    assert_eq!(job.error.as_deref(), Some(INTERRUPTED));
    assert_eq!(ledger.rows.lock().unwrap()[0].phase, DownloadPhase::Failed);
}

#[tokio::test]
async fn removing_a_finished_download_can_delete_its_file() {
    let ledger = Arc::new(MemoryLedger::default());
    let downloader = Arc::new(FakeDownloader::default());
    let queue = queue_with(ledger.clone(), downloader.clone()).await;
    let job = queue.enqueue(target(6.0), stream()).await.unwrap();
    settled(&queue, job.id).await;
    queue.remove(job.id, true).await.unwrap();
    assert!(queue.snapshot().is_empty());
    assert!(ledger.rows.lock().unwrap().is_empty());
    assert_eq!(
        downloader.discarded.lock().unwrap().as_slice(),
        ["/films/1.mkv"]
    );
}

#[tokio::test]
async fn a_finished_file_moved_elsewhere_keeps_its_new_place() {
    let ledger = Arc::new(MemoryLedger::default());
    let queue = queue_with(ledger.clone(), Arc::new(FakeDownloader::default())).await;
    let job = queue.enqueue(target(7.0), stream()).await.unwrap();
    settled(&queue, job.id).await;
    queue
        .relocate(job.id, "content://media/7".into())
        .await
        .unwrap();
    assert_eq!(
        queue.snapshot()[0].file_path.as_deref(),
        Some("content://media/7")
    );
    assert_eq!(
        ledger.rows.lock().unwrap()[0].file_path.as_deref(),
        Some("content://media/7")
    );
}

#[tokio::test]
async fn an_unfinished_download_cannot_be_moved() {
    let downloader = Arc::new(FakeDownloader::default());
    *downloader.failing.lock().unwrap() = true;
    let queue = queue_with(Arc::new(MemoryLedger::default()), downloader).await;
    let job = queue.enqueue(target(8.0), stream()).await.unwrap();
    settled(&queue, job.id).await;
    queue
        .relocate(job.id, "content://media/8".into())
        .await
        .unwrap();
    assert_eq!(queue.snapshot()[0].file_path, None);
}
