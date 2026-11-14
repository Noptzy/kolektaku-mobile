use domain::media::{MediaFormat, MediaId, MediaStatus};
use serde::Deserialize;

use super::lenient::lenient;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum RawKind {
    Anime,
    Manga,
}

#[derive(Debug, Deserialize)]
pub struct RawTitle {
    pub romaji: Option<String>,
    pub english: Option<String>,
    pub native: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawImage {
    pub large: Option<String>,
    pub extra_large: Option<String>,
}

#[derive(Debug, Clone, Copy, Default, Deserialize)]
pub struct RawDate {
    pub year: Option<u16>,
    pub month: Option<u8>,
    pub day: Option<u8>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawSummary {
    pub id: MediaId,
    #[serde(rename = "type")]
    pub kind: RawKind,
    pub title: RawTitle,
    pub synonyms: Option<Vec<String>>,
    pub cover_image: Option<RawImage>,
    #[serde(default, deserialize_with = "lenient")]
    pub format: Option<MediaFormat>,
    #[serde(default, deserialize_with = "lenient")]
    pub status: Option<MediaStatus>,
    pub season_year: Option<u16>,
    pub start_date: Option<RawDate>,
    pub episodes: Option<u32>,
    pub chapters: Option<u32>,
    pub average_score: Option<f64>,
    pub genres: Option<Vec<String>>,
    pub country_of_origin: Option<String>,
    pub is_adult: Option<bool>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_minimum_a_catalog_must_send() {
        let json = r#"{"id":21,"type":"ANIME","title":{"romaji":"ONE PIECE"}}"#;
        let raw: RawSummary = serde_json::from_str(json).unwrap();
        assert_eq!(raw.id.get(), 21);
        assert_eq!(raw.kind, RawKind::Anime);
        assert_eq!(raw.title.english, None);
        assert_eq!(raw.format, None);
    }

    #[test]
    fn an_unknown_format_is_tolerated_but_a_wrong_id_is_not() {
        let tolerated = r#"{"id":1,"type":"MANGA","title":{},"format":"NEW_KIND"}"#;
        assert!(serde_json::from_str::<RawSummary>(tolerated).is_ok());
        let broken = r#"{"id":"x","type":"MANGA","title":{}}"#;
        assert!(serde_json::from_str::<RawSummary>(broken).is_err());
        let zero = r#"{"id":0,"type":"MANGA","title":{}}"#;
        assert!(serde_json::from_str::<RawSummary>(zero).is_err());
    }
}
