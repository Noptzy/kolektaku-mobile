use std::future::Future;

use domain::error::SourceError;
use domain::scene::SceneReply;

pub trait SceneSearch: Send + Sync {
    fn find(&self, image: Vec<u8>) -> impl Future<Output = Result<SceneReply, SourceError>> + Send;

    fn quota_left(&self) -> impl Future<Output = Result<u32, SourceError>> + Send;
}
