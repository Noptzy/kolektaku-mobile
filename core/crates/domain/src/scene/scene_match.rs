use serde::{Deserialize, Serialize};

use crate::media::MediaId;

pub const LEAD_IN_SECS: f64 = 3.0;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SceneMatch {
    pub media_id: MediaId,
    pub episode: Option<f64>,
    pub from_secs: f64,
    pub at_secs: f64,
    pub to_secs: f64,
    pub similarity: f32,
    pub preview_image_url: Option<String>,
    pub title: Option<String>,
    pub is_adult: bool,
    pub duration_secs: Option<f64>,
}

impl SceneMatch {
    pub fn start_secs(&self) -> f64 {
        (self.at_secs - LEAD_IN_SECS).max(0.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn scene(at_secs: f64) -> SceneMatch {
        SceneMatch {
            media_id: MediaId::new(21034).unwrap(),
            episode: Some(1.0),
            from_secs: at_secs - 2.0,
            at_secs,
            to_secs: at_secs + 2.0,
            similarity: 0.99,
            preview_image_url: None,
            title: None,
            is_adult: false,
            duration_secs: None,
        }
    }

    #[test]
    fn playback_starts_a_few_seconds_before_the_matched_frame() {
        assert_eq!(scene(279.78).start_secs(), 279.78 - 3.0);
    }

    #[test]
    fn start_never_goes_below_zero() {
        assert_eq!(scene(1.5).start_secs(), 0.0);
    }
}
