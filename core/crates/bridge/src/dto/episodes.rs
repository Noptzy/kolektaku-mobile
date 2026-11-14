use domain::media::EpisodeInfo;

#[derive(Debug, Clone, PartialEq)]
pub struct EpisodeInfoDto {
    pub number: f64,
    pub title: String,
    pub thumbnail_url: Option<String>,
}

impl From<&EpisodeInfo> for EpisodeInfoDto {
    fn from(episode: &EpisodeInfo) -> Self {
        Self {
            number: episode.number,
            title: episode.title.clone(),
            thumbnail_url: episode.thumbnail_url.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn an_episode_keeps_its_number_title_and_picture() {
        let mut episode = EpisodeInfo::new(5.0, "Cruelty");
        episode.thumbnail_url = Some("https://img.test/5.jpg".into());
        let dto = EpisodeInfoDto::from(&episode);
        assert_eq!(dto.number, 5.0);
        assert_eq!(dto.title, "Cruelty");
        assert_eq!(dto.thumbnail_url.as_deref(), Some("https://img.test/5.jpg"));
    }

    #[test]
    fn a_detail_carries_its_episodes_to_the_bridge() {
        use domain::media::{MediaDetail, MediaId, MediaKind, MediaSummary, MediaTitle};

        use crate::dto::credits::MediaDetailDto;

        let summary = MediaSummary::new(
            MediaId::new(3).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("X"),
        );
        let mut detail = MediaDetail::new(summary);
        detail.episodes = vec![EpisodeInfo::new(1.0, "A"), EpisodeInfo::new(2.0, "B")];
        let dto = MediaDetailDto::from(&detail);
        let titles: Vec<&str> = dto
            .episodes
            .iter()
            .map(|item| item.title.as_str())
            .collect();
        assert_eq!(titles, vec!["A", "B"]);
    }
}
