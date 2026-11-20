use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Mutex;

use application::downloads::CancelToken;
use application::ports::BoxFuture;
use domain::error::SourceError;

use super::bytes::{ByteFetcher, ByteProgress};
use crate::http::HttpRequest;

type Answer = Result<Vec<u8>, SourceError>;

#[derive(Default)]
pub struct FakeBytes {
    answers: Mutex<HashMap<String, Vec<Answer>>>,
    pub asked: Mutex<Vec<HttpRequest>>,
}

impl FakeBytes {
    pub fn with(self, url: &str, answer: Result<Vec<u8>, SourceError>) -> Self {
        self.answers
            .lock()
            .unwrap()
            .entry(url.to_string())
            .or_default()
            .push(answer);
        self
    }

    fn answer(&self, request: HttpRequest) -> Result<Vec<u8>, SourceError> {
        let url = request.url.clone();
        self.asked.lock().unwrap().push(request);
        let mut answers = self.answers.lock().unwrap();
        let queue = answers
            .get_mut(&url)
            .ok_or_else(|| SourceError::NotFound(url.clone()))?;
        if queue.len() > 1 {
            queue.remove(0)
        } else {
            queue[0].clone()
        }
    }
}

impl ByteFetcher for FakeBytes {
    fn fetch(&self, request: HttpRequest) -> BoxFuture<'_, Result<Vec<u8>, SourceError>> {
        Box::pin(async move { self.answer(request) })
    }

    fn save(
        &self,
        request: HttpRequest,
        path: PathBuf,
        _cancel: CancelToken,
        progress: ByteProgress,
    ) -> BoxFuture<'_, Result<u64, SourceError>> {
        Box::pin(async move {
            let bytes = self.answer(request)?;
            std::fs::write(&path, &bytes)
                .map_err(|error| SourceError::Unavailable(error.to_string()))?;
            progress(bytes.len() as u64, Some(bytes.len() as u64));
            Ok(bytes.len() as u64)
        })
    }
}
