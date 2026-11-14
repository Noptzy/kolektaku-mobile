use domain::error::SourceError;
use domain::stream::{EpisodeServer, StreamPlan, StreamSet};

use super::BoxFuture;

pub trait VideoSource: Send + Sync {
    fn servers(&self, episode: String) -> BoxFuture<'_, Result<Vec<EpisodeServer>, SourceError>>;

    fn stream_plan(
        &self,
        episode: String,
        server: String,
    ) -> BoxFuture<'_, Result<StreamPlan, SourceError>>;

    fn parse_stream_payload(&self, payload: &str) -> Result<StreamSet, SourceError>;
}
