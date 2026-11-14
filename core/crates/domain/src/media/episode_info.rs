use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EpisodeInfo {
    pub number: f64,
    pub title: String,
    pub thumbnail_url: Option<String>,
}

impl EpisodeInfo {
    pub fn new(number: f64, title: impl Into<String>) -> Self {
        Self {
            number,
            title: title.into(),
            thumbnail_url: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_new_episode_has_no_thumbnail() {
        let episode = EpisodeInfo::new(5.0, "Cruelty");
        assert_eq!(episode.number, 5.0);
        assert_eq!(episode.title, "Cruelty");
        assert_eq!(episode.thumbnail_url, None);
    }
}
