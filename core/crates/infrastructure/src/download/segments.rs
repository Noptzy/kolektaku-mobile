use std::collections::VecDeque;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;

use application::downloads::CancelToken;
use domain::error::SourceError;
use tokio::io::AsyncWriteExt;
use tokio::task::JoinHandle;

use super::bytes::ByteFetcher;
use crate::http::HttpRequest;

pub const PARALLEL_SEGMENTS: usize = 4;
const ATTEMPTS: u32 = 3;
const RETRY_PAUSE: Duration = Duration::from_millis(800);

pub struct SegmentBatch<'a> {
    pub fetcher: Arc<dyn ByteFetcher>,
    pub urls: Vec<String>,
    pub headers: Vec<(String, String)>,
    pub output: &'a Path,
    pub cancel: CancelToken,
}

fn request(url: &str, headers: &[(String, String)]) -> HttpRequest {
    headers
        .iter()
        .fold(HttpRequest::get(url), |request, (name, value)| {
            request.with_header(name, value)
        })
}

async fn fetch_with_retries(
    fetcher: Arc<dyn ByteFetcher>,
    url: String,
    headers: Vec<(String, String)>,
) -> Result<Vec<u8>, SourceError> {
    let mut last = None;
    for attempt in 0..ATTEMPTS {
        if attempt > 0 {
            tokio::time::sleep(RETRY_PAUSE * attempt).await;
        }
        match fetcher.fetch(request(&url, &headers)).await {
            Ok(bytes) => return Ok(bytes),
            Err(SourceError::NotFound(detail)) => return Err(SourceError::NotFound(detail)),
            Err(error) => last = Some(error),
        }
    }
    Err(last.unwrap_or_else(|| SourceError::Network("no answer".into())))
}

fn write_error(error: std::io::Error) -> SourceError {
    SourceError::Unavailable(format!("the file could not be written: {error}"))
}

pub async fn fetch_segments(
    batch: SegmentBatch<'_>,
    on_segment: &(dyn Fn(u64) + Send + Sync),
) -> Result<u64, SourceError> {
    let mut file = tokio::fs::File::create(batch.output)
        .await
        .map_err(write_error)?;
    let mut waiting: VecDeque<JoinHandle<Result<Vec<u8>, SourceError>>> = VecDeque::new();
    let mut urls = batch.urls.into_iter();
    let mut total = 0u64;
    loop {
        while waiting.len() < PARALLEL_SEGMENTS {
            let Some(url) = urls.next() else { break };
            let (fetcher, headers) = (Arc::clone(&batch.fetcher), batch.headers.clone());
            waiting.push_back(tokio::spawn(fetch_with_retries(fetcher, url, headers)));
        }
        let Some(next) = waiting.pop_front() else {
            break;
        };
        if batch.cancel.is_cancelled() {
            waiting.iter().for_each(JoinHandle::abort);
            return Err(SourceError::Unavailable("the download was stopped".into()));
        }
        let bytes = next
            .await
            .map_err(|error| SourceError::Unavailable(error.to_string()))??;
        file.write_all(&bytes).await.map_err(write_error)?;
        total += bytes.len() as u64;
        on_segment(bytes.len() as u64);
    }
    file.flush().await.map_err(write_error)?;
    Ok(total)
}

#[cfg(test)]
mod tests {
    use std::sync::Mutex;

    use super::*;
    use crate::download::fake_bytes::FakeBytes;

    fn temp(name: &str) -> std::path::PathBuf {
        std::env::temp_dir().join(format!("kolektaku-seg-{name}-{}", std::process::id()))
    }

    fn batch(fetcher: Arc<FakeBytes>, count: usize, output: &Path) -> SegmentBatch<'_> {
        SegmentBatch {
            fetcher,
            urls: (0..count)
                .map(|index| format!("https://cdn.test/{index}.ts"))
                .collect(),
            headers: vec![("referer".into(), "https://site.test/".into())],
            output,
            cancel: CancelToken::default(),
        }
    }

    #[tokio::test]
    async fn segments_are_joined_in_playlist_order_and_counted() {
        let mut fake = FakeBytes::default();
        for index in 0..9u8 {
            fake = fake.with(&format!("https://cdn.test/{index}.ts"), Ok(vec![index; 3]));
        }
        let fake = Arc::new(fake);
        let output = temp("order");
        let seen = Mutex::new(0u64);
        let total = fetch_segments(batch(fake.clone(), 9, &output), &|bytes| {
            *seen.lock().unwrap() += bytes
        })
        .await
        .unwrap();
        let written = std::fs::read(&output).unwrap();
        let expected: Vec<u8> = (0..9u8).flat_map(|index| [index; 3]).collect();
        assert_eq!(written, expected);
        assert_eq!((total, *seen.lock().unwrap()), (27, 27));
        assert_eq!(fake.asked.lock().unwrap()[0].headers[0].0, "referer");
        let _ = std::fs::remove_file(output);
    }

    #[tokio::test]
    async fn a_shaky_segment_is_tried_again_but_a_missing_one_fails_at_once() {
        let fake = Arc::new(
            FakeBytes::default()
                .with(
                    "https://cdn.test/0.ts",
                    Err(SourceError::Network("blip".into())),
                )
                .with("https://cdn.test/0.ts", Ok(vec![1]))
                .with(
                    "https://cdn.test/1.ts",
                    Err(SourceError::NotFound("gone".into())),
                ),
        );
        let output = temp("retry");
        let outcome = fetch_segments(batch(fake.clone(), 2, &output), &|_| {}).await;
        assert!(matches!(outcome, Err(SourceError::NotFound(_))));
        let asked = fake.asked.lock().unwrap();
        assert_eq!(asked.iter().filter(|r| r.url.ends_with("/1.ts")).count(), 1);
        assert_eq!(asked.iter().filter(|r| r.url.ends_with("/0.ts")).count(), 2);
        let _ = std::fs::remove_file(output);
    }

    #[tokio::test]
    async fn a_cancelled_batch_stops() {
        let fake = Arc::new(FakeBytes::default().with("https://cdn.test/0.ts", Ok(vec![1])));
        let output = temp("cancel");
        let job = batch(fake, 1, &output);
        job.cancel.cancel();
        assert!(fetch_segments(job, &|_| {}).await.is_err());
        let _ = std::fs::remove_file(output);
    }
}
