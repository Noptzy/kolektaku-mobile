use std::path::PathBuf;
use std::sync::Arc;

use application::downloads::CancelToken;
use application::ports::BoxFuture;
use domain::error::SourceError;
use tokio::io::AsyncWriteExt;

use crate::http::{HttpRequest, ReqwestClient};

pub type ByteProgress = Arc<dyn Fn(u64, Option<u64>) + Send + Sync>;

pub trait ByteFetcher: Send + Sync {
    fn fetch(&self, request: HttpRequest) -> BoxFuture<'_, Result<Vec<u8>, SourceError>>;

    fn save(
        &self,
        request: HttpRequest,
        path: PathBuf,
        cancel: CancelToken,
        progress: ByteProgress,
    ) -> BoxFuture<'_, Result<u64, SourceError>>;
}

pub fn status_error(status: u16) -> SourceError {
    match status {
        404 | 410 => SourceError::NotFound(format!("the video file answered {status}")),
        429 => SourceError::RateLimited {
            retry_after_secs: None,
        },
        other => SourceError::Unavailable(format!("the video file answered {other}")),
    }
}

fn file_error(error: std::io::Error) -> SourceError {
    SourceError::Unavailable(format!("the file could not be written: {error}"))
}

fn stopped() -> SourceError {
    SourceError::Unavailable("the download was stopped".into())
}

impl ByteFetcher for ReqwestClient {
    fn fetch(&self, request: HttpRequest) -> BoxFuture<'_, Result<Vec<u8>, SourceError>> {
        Box::pin(async move {
            let response = self.open(request).await?;
            let status = response.status().as_u16();
            if !(200..300).contains(&status) {
                return Err(status_error(status));
            }
            let bytes = response.bytes().await.map_err(crate::http::network_error)?;
            Ok(bytes.to_vec())
        })
    }

    fn save(
        &self,
        request: HttpRequest,
        path: PathBuf,
        cancel: CancelToken,
        progress: ByteProgress,
    ) -> BoxFuture<'_, Result<u64, SourceError>> {
        Box::pin(async move {
            let mut response = self.open(request).await?;
            let status = response.status().as_u16();
            if !(200..300).contains(&status) {
                return Err(status_error(status));
            }
            let total = response.content_length();
            let mut file = tokio::fs::File::create(&path).await.map_err(file_error)?;
            let mut written = 0u64;
            while let Some(chunk) = response.chunk().await.map_err(crate::http::network_error)? {
                if cancel.is_cancelled() {
                    return Err(stopped());
                }
                file.write_all(&chunk).await.map_err(file_error)?;
                written += chunk.len() as u64;
                progress(written, total);
            }
            file.flush().await.map_err(file_error)?;
            Ok(written)
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn missing_files_and_refusals_become_the_matching_errors() {
        assert!(matches!(status_error(404), SourceError::NotFound(_)));
        assert!(matches!(status_error(429), SourceError::RateLimited { .. }));
        assert!(matches!(status_error(403), SourceError::Unavailable(_)));
    }
}
