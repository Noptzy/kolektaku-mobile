use serde::{Deserialize, Serialize};

use super::{MediaFormat, MediaId, MediaKind, MediaStatus, MediaTitle};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MediaSummary {
    pub id: MediaId,
    pub kind: MediaKind,
    pub title: MediaTitle,
    pub synonyms: Vec<String>,
    pub cover_url: Option<String>,
    #[serde(default)]
    pub cover_hd_url: Option<String>,
    #[serde(default)]
    pub synopsis: Option<String>,
    pub format: Option<MediaFormat>,
    pub status: Option<MediaStatus>,
    pub year: Option<u16>,
    pub unit_count: Option<u32>,
    pub score: Option<f32>,
    pub genres: Vec<String>,
    pub country_of_origin: Option<String>,
    pub is_adult: bool,
    #[serde(default)]
    pub id_mal: Option<u64>,
}

impl MediaSummary {
    pub fn new(id: MediaId, kind: MediaKind, title: MediaTitle) -> Self {
        Self {
            id,
            kind,
            title,
            synonyms: Vec::new(),
            cover_url: None,
            cover_hd_url: None,
            synopsis: None,
            format: None,
            status: None,
            year: None,
            unit_count: None,
            score: None,
            genres: Vec::new(),
            country_of_origin: None,
            is_adult: false,
            id_mal: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_starts_with_empty_optional_fields() {
        let summary = MediaSummary::new(
            MediaId::new(1).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Naruto"),
        );
        assert!(summary.synonyms.is_empty());
        assert_eq!(summary.format, None);
        assert!(!summary.is_adult);
    }

    #[test]
    fn survives_a_json_round_trip() {
        let mut summary = MediaSummary::new(
            MediaId::new(21519).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Kimi no Na wa."),
        );
        summary.format = Some(MediaFormat::Movie);
        summary.year = Some(2016);
        let json = serde_json::to_string(&summary).unwrap();
        assert_eq!(
            serde_json::from_str::<MediaSummary>(&json).unwrap(),
            summary
        );
    }
}
