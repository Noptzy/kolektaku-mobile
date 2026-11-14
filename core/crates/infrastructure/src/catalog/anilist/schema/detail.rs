use serde::Deserialize;

use super::credits::{
    RawCharacterEdge, RawEdges, RawRecommendations, RawRelationEdge, RawStaffEdge,
};
use super::summary::{RawDate, RawSummary};

#[derive(Debug, Deserialize)]
pub struct RawStudio {
    #[serde(default)]
    pub id: Option<u64>,
    pub name: String,
}

#[derive(Debug, Deserialize)]
pub struct RawStudios {
    pub nodes: Option<Vec<RawStudio>>,
}

#[derive(Debug, Deserialize)]
pub struct RawTrailer {
    pub id: Option<String>,
    pub site: Option<String>,
    pub thumbnail: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawExternalLink {
    pub site: Option<String>,
    pub url: Option<String>,
    #[serde(rename = "type")]
    pub kind: Option<String>,
    pub is_disabled: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct RawStreamingEpisode {
    pub title: Option<String>,
    pub thumbnail: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawAiring {
    pub episode: u32,
    pub airing_at: u64,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawDetail {
    #[serde(flatten)]
    pub summary: RawSummary,
    pub id_mal: Option<u64>,
    pub banner_image: Option<String>,
    pub description: Option<String>,
    pub duration: Option<u32>,
    pub season: Option<String>,
    pub source: Option<String>,
    pub site_url: Option<String>,
    pub end_date: Option<RawDate>,
    pub studios: Option<RawStudios>,
    pub trailer: Option<RawTrailer>,
    pub next_airing_episode: Option<RawAiring>,
    pub streaming_episodes: Option<Vec<RawStreamingEpisode>>,
    pub external_links: Option<Vec<RawExternalLink>>,
    pub characters: Option<RawEdges<RawCharacterEdge>>,
    pub staff: Option<RawEdges<RawStaffEdge>>,
    pub relations: Option<RawEdges<RawRelationEdge>>,
    pub recommendations: Option<RawRecommendations>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn flattens_the_summary_fields_next_to_the_detail_fields() {
        let json = r#"{"id":5,"type":"ANIME","title":{"romaji":"X"},"bannerImage":"b","duration":24,
            "nextAiringEpisode":{"episode":3,"airingAt":1700000000},"trailer":{"id":"abc","site":"youtube","thumbnail":null}}"#;
        let raw: RawDetail = serde_json::from_str(json).unwrap();
        assert_eq!(raw.summary.id.get(), 5);
        assert_eq!(raw.banner_image.as_deref(), Some("b"));
        assert_eq!(raw.duration, Some(24));
        assert_eq!(
            raw.next_airing_episode.map(|airing| airing.episode),
            Some(3)
        );
        assert_eq!(
            raw.trailer.and_then(|trailer| trailer.id).as_deref(),
            Some("abc")
        );
    }
}
