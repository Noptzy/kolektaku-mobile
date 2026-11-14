use std::sync::Mutex;

use domain::error::SourceError;
use domain::scene::{SceneMatch, SceneReply};

use crate::ports::SceneSearch;

pub struct FakeSceneSearch {
    result: Result<SceneReply, SourceError>,
    image_sizes: Mutex<Vec<usize>>,
}

impl FakeSceneSearch {
    pub fn returning(matches: Vec<SceneMatch>) -> Self {
        Self::replying(SceneReply {
            matches,
            quota_left: None,
        })
    }

    pub fn replying(reply: SceneReply) -> Self {
        Self {
            result: Ok(reply),
            image_sizes: Mutex::new(Vec::new()),
        }
    }

    pub fn failing_with(error: SourceError) -> Self {
        Self {
            result: Err(error),
            image_sizes: Mutex::new(Vec::new()),
        }
    }

    pub fn image_sizes(&self) -> Vec<usize> {
        self.image_sizes.lock().unwrap().clone()
    }
}

impl SceneSearch for FakeSceneSearch {
    async fn find(&self, image: Vec<u8>) -> Result<SceneReply, SourceError> {
        self.image_sizes.lock().unwrap().push(image.len());
        self.result.clone()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn returns_the_scripted_matches_and_records_image_sizes() {
        let search = FakeSceneSearch::returning(Vec::new());
        assert!(search.find(vec![0; 10]).await.unwrap().matches.is_empty());
        assert_eq!(search.image_sizes(), vec![10]);
    }

    #[tokio::test]
    async fn returns_the_scripted_error() {
        let search = FakeSceneSearch::failing_with(SourceError::QuotaExceeded);
        assert_eq!(
            search.find(Vec::new()).await,
            Err(SourceError::QuotaExceeded)
        );
    }
}
