use application::ports::BoxFuture;
use domain::error::SourceError;

use super::{HttpRequest, HttpResponse};

pub trait HttpClient: Send + Sync {
    fn send(&self, request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>>;
}
