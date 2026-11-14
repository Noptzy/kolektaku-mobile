use std::sync::Arc;

use application::ports::SceneSearch;
use domain::error::SourceError;
use domain::scene::SceneReply;
use tokio::sync::Mutex;

use super::mapper::to_reply;
use super::schema::RawReply;
use crate::http::{HttpClient, HttpRequest, HttpResponse, Pause};

const ENDPOINT: &str = "https://api.trace.moe/search?cutBorders&anilistInfo";
const MAX_RETRIES: u32 = 2;
const BASE_DELAY_MS: u64 = 2_000;
const LONGEST_WAIT_MS: u64 = 10_000;

pub struct TraceMoeSceneSearch {
    http: Arc<dyn HttpClient>,
    pause: Arc<dyn Pause>,
    one_at_a_time: Mutex<()>,
}

impl TraceMoeSceneSearch {
    pub fn new(http: Arc<dyn HttpClient>, pause: Arc<dyn Pause>) -> Self {
        Self {
            http,
            pause,
            one_at_a_time: Mutex::new(()),
        }
    }

    fn wait_before_retry(response: &HttpResponse, retry: u32) -> u64 {
        match response.header_number("retry-after") {
            Some(seconds) => (seconds * 1_000).min(LONGEST_WAIT_MS),
            None => BASE_DELAY_MS * u64::from(retry),
        }
    }
}

fn read_reply(body: &str) -> Result<SceneReply, SourceError> {
    let reply: RawReply = serde_json::from_str(body)
        .map_err(|error| SourceError::MarkupChanged(format!("trace.moe reply: {error}")))?;
    if let Some(message) = reply.error.as_deref().filter(|text| !text.is_empty()) {
        return Err(failure_from_message(message));
    }
    Ok(to_reply(reply))
}

fn failure_from_message(message: &str) -> SourceError {
    if message.to_lowercase().contains("quota") {
        SourceError::QuotaExceeded
    } else {
        SourceError::Unavailable(message.to_string())
    }
}

impl SceneSearch for TraceMoeSceneSearch {
    async fn find(&self, image: Vec<u8>) -> Result<SceneReply, SourceError> {
        if image.is_empty() {
            return Err(SourceError::Unsupported("empty image".into()));
        }
        let _turn = self.one_at_a_time.lock().await;
        let mut retries = 0;
        loop {
            let request = HttpRequest::post_bytes(ENDPOINT, image.clone(), "image/jpeg");
            let response = self.http.send(request).await?;
            match response.status {
                200..=299 => return read_reply(&response.body),
                402 => return Err(SourceError::QuotaExceeded),
                429 | 503 if retries < MAX_RETRIES => {
                    retries += 1;
                    self.pause
                        .sleep(Self::wait_before_retry(&response, retries))
                        .await;
                }
                429 | 503 => {
                    return Err(SourceError::RateLimited {
                        retry_after_secs: response.header_number("retry-after"),
                    });
                }
                400 => return Err(SourceError::Unsupported("image was rejected".into())),
                status => return Err(SourceError::Unavailable(format!("http {status}"))),
            }
        }
    }
}
