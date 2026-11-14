use serde::{Deserialize, Serialize};

use super::{
    Character, EpisodeInfo, ExternalLink, MediaDate, MediaSummary, NextAiring, Relation, Staff,
    StudioRef, Trailer,
};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MediaDetail {
    pub summary: MediaSummary,
    pub banner_url: Option<String>,
    pub description: String,
    pub studios: Vec<StudioRef>,
    pub source: Option<String>,
    pub season: Option<String>,
    pub start_date: MediaDate,
    pub end_date: MediaDate,
    pub duration_minutes: Option<u32>,
    pub site_url: Option<String>,
    pub characters: Vec<Character>,
    pub staff: Vec<Staff>,
    pub trailer: Option<Trailer>,
    pub relations: Vec<Relation>,
    pub recommendations: Vec<MediaSummary>,
    pub next_airing: Option<NextAiring>,
    pub episodes: Vec<EpisodeInfo>,
    pub mal_id: Option<u64>,
    pub links: Vec<ExternalLink>,
}

impl MediaDetail {
    pub fn new(summary: MediaSummary) -> Self {
        Self {
            summary,
            banner_url: None,
            description: String::new(),
            studios: Vec::new(),
            source: None,
            season: None,
            start_date: MediaDate::default(),
            end_date: MediaDate::default(),
            duration_minutes: None,
            site_url: None,
            characters: Vec::new(),
            staff: Vec::new(),
            trailer: None,
            relations: Vec::new(),
            recommendations: Vec::new(),
            next_airing: None,
            episodes: Vec::new(),
            mal_id: None,
            links: Vec::new(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::media::{MediaId, MediaKind, MediaTitle};

    #[test]
    fn new_wraps_the_summary_with_empty_extras() {
        let summary = MediaSummary::new(
            MediaId::new(7).unwrap(),
            MediaKind::Manga,
            MediaTitle::new("Berserk"),
        );
        let detail = MediaDetail::new(summary.clone());
        assert_eq!(detail.summary, summary);
        assert!(detail.characters.is_empty());
        assert_eq!(detail.next_airing, None);
    }
}
