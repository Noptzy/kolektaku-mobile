use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TrailerSite {
    Youtube,
    Dailymotion,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Trailer {
    pub site: TrailerSite,
    pub video_id: String,
    pub thumbnail_url: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn site_uses_lowercase_names() {
        assert_eq!(
            serde_json::to_string(&TrailerSite::Youtube).unwrap(),
            "\"youtube\""
        );
    }
}
