use application::downloads::{CancelToken, DownloadOrder, DownloadProgress, ProgressSink};
use domain::download::DownloadPhase;
use domain::error::SourceError;

use crate::http::HttpRequest;

pub struct Session<'a> {
    pub order: &'a DownloadOrder,
    pub progress: &'a ProgressSink,
    pub cancel: &'a CancelToken,
}

impl Session<'_> {
    pub fn report(&self, phase: DownloadPhase, fraction: f32, bytes: u64) {
        (self.progress)(DownloadProgress {
            phase,
            fraction,
            bytes,
        });
    }

    pub fn check_stopped(&self) -> Result<(), SourceError> {
        if self.cancel.is_cancelled() {
            return Err(SourceError::Unavailable("the download was stopped".into()));
        }
        Ok(())
    }

    pub fn headers(&self) -> Vec<(String, String)> {
        self.order.job.stream.headers.clone()
    }

    pub fn request(&self, url: &str) -> HttpRequest {
        self.order
            .job
            .stream
            .headers
            .iter()
            .fold(HttpRequest::get(url), |request, (name, value)| {
                request.with_header(name, value)
            })
    }

    pub fn file_stem(&self) -> String {
        self.order.job.target.file_stem()
    }
}

pub fn folder_error(error: std::io::Error) -> SourceError {
    SourceError::Unavailable(format!("the download folder is not usable: {error}"))
}
