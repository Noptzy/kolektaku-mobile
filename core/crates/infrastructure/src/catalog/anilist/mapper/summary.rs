use domain::media::{MediaFormat, MediaKind, MediaSummary, MediaTitle};

use super::synopsis::brief_synopsis;
use crate::catalog::anilist::schema::{RawKind, RawSummary};

const SYNOPSIS_WORDS: usize = 100;

const UNTITLED: &str = "Tanpa judul";

fn media_kind(raw: RawKind, format: Option<MediaFormat>) -> MediaKind {
    match (raw, format) {
        (RawKind::Anime, _) => MediaKind::Anime,
        (RawKind::Manga, Some(MediaFormat::Novel)) => MediaKind::Novel,
        (RawKind::Manga, _) => MediaKind::Manga,
    }
}

pub fn is_visible(raw: &RawSummary) -> bool {
    raw.is_adult != Some(true)
}

pub fn visible_summaries(raw: Vec<RawSummary>) -> Vec<MediaSummary> {
    raw.into_iter()
        .filter(is_visible)
        .map(map_summary)
        .collect()
}

pub fn map_summary(raw: RawSummary) -> MediaSummary {
    let kind = media_kind(raw.kind, raw.format);
    let romaji = raw
        .title
        .romaji
        .clone()
        .or_else(|| raw.title.english.clone())
        .or_else(|| raw.title.native.clone())
        .unwrap_or_else(|| UNTITLED.to_string());
    let unit_count = match kind {
        MediaKind::Anime => raw.episodes,
        MediaKind::Manga | MediaKind::Novel => raw.chapters,
    };
    MediaSummary {
        id: raw.id,
        kind,
        title: MediaTitle {
            romaji,
            english: raw.title.english,
            native: raw.title.native,
        },
        synonyms: raw
            .synonyms
            .unwrap_or_default()
            .into_iter()
            .map(|synonym| synonym.trim().to_string())
            .filter(|synonym| !synonym.is_empty())
            .collect(),
        cover_hd_url: raw
            .cover_image
            .as_ref()
            .and_then(|image| image.extra_large.clone()),
        cover_url: raw
            .cover_image
            .and_then(|image| image.large.or(image.extra_large)),
        synopsis: raw
            .synopsis
            .as_deref()
            .and_then(|text| brief_synopsis(text, SYNOPSIS_WORDS)),
        format: raw.format,
        status: raw.status,
        year: raw
            .season_year
            .or_else(|| raw.start_date.and_then(|date| date.year)),
        unit_count,
        score: raw.average_score.map(|score| score.round() as f32 / 10.0),
        genres: raw.genres.unwrap_or_default(),
        country_of_origin: raw.country_of_origin,
        is_adult: raw.is_adult.unwrap_or(false),
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaFormat, MediaStatus};

    use super::*;

    fn raw(json: &str) -> RawSummary {
        serde_json::from_str(json).unwrap()
    }

    #[test]
    fn maps_the_catalog_fields_to_the_domain_summary() {
        let summary = map_summary(raw(
            r#"{"id":21,"type":"ANIME","title":{"romaji":"ONE PIECE","english":"One Piece","native":"ワンピース"},
            "synonyms":[" OP ","", "Vua Hải Tặc"],"coverImage":{"large":"https://x/l.jpg"},"format":"TV","status":"RELEASING",
            "seasonYear":1999,"episodes":null,"chapters":1100,"averageScore":87,"genres":["Action"],"countryOfOrigin":"JP"}"#,
        ));
        assert_eq!(summary.id.get(), 21);
        assert_eq!(summary.kind, MediaKind::Anime);
        assert_eq!(summary.title.romaji, "ONE PIECE");
        assert_eq!(summary.synonyms, vec!["OP", "Vua Hải Tặc"]);
        assert_eq!(summary.cover_url.as_deref(), Some("https://x/l.jpg"));
        assert_eq!(summary.format, Some(MediaFormat::Tv));
        assert_eq!(summary.status, Some(MediaStatus::Releasing));
        assert_eq!(summary.year, Some(1999));
        assert_eq!(summary.unit_count, None);
        assert_eq!(summary.score, Some(8.7));
        assert_eq!(summary.country_of_origin.as_deref(), Some("JP"));
        assert!(!summary.is_adult);
    }

    #[test]
    fn manga_counts_chapters_and_keeps_both_cover_sizes() {
        let summary = map_summary(raw(
            r#"{"id":2,"type":"MANGA","title":{"romaji":"Berserk"},"episodes":9,"chapters":364,
            "coverImage":{"large":"l","extraLarge":"xl"},"startDate":{"year":1989}}"#,
        ));
        assert_eq!(summary.kind, MediaKind::Manga);
        assert_eq!(summary.unit_count, Some(364));
        assert_eq!(summary.cover_url.as_deref(), Some("l"));
        assert_eq!(summary.cover_hd_url.as_deref(), Some("xl"));
        assert_eq!(summary.year, Some(1989));
    }

    #[test]
    fn the_only_cover_sent_is_still_used_for_cards() {
        let summary = map_summary(raw(
            r#"{"id":3,"type":"ANIME","title":{"romaji":"X"},"coverImage":{"extraLarge":"xl"}}"#,
        ));
        assert_eq!(summary.cover_url.as_deref(), Some("xl"));
        assert_eq!(summary.cover_hd_url.as_deref(), Some("xl"));
    }

    #[test]
    fn the_synopsis_is_cleaned_and_capped_at_one_hundred_words() {
        let long = (1..=130)
            .map(|n| format!("w{n}"))
            .collect::<Vec<_>>()
            .join(" ");
        let json = format!(
            r#"{{"id":4,"type":"ANIME","title":{{"romaji":"X"}},"synopsis":"Intro<br>~!spoiler!~ {long}"}}"#
        );
        let summary = map_summary(raw(&json));
        let text = summary.synopsis.unwrap();
        assert!(text.starts_with("Intro w1 w2"));
        assert!(text.ends_with('…'));
        assert!(!text.contains("spoiler"));
        assert_eq!(text.trim_end_matches('…').split(' ').count(), 100);
    }

    #[test]
    fn a_missing_synopsis_stays_empty() {
        let summary = map_summary(raw(r#"{"id":5,"type":"ANIME","title":{"romaji":"X"}}"#));
        assert_eq!(summary.synopsis, None);
        assert_eq!(summary.cover_hd_url, None);
    }

    #[test]
    fn the_title_falls_back_through_english_native_then_a_placeholder() {
        let english = map_summary(raw(
            r#"{"id":1,"type":"ANIME","title":{"english":"E","native":"N"}}"#,
        ));
        assert_eq!(english.title.romaji, "E");
        let native = map_summary(raw(r#"{"id":1,"type":"ANIME","title":{"native":"N"}}"#));
        assert_eq!(native.title.romaji, "N");
        let none = map_summary(raw(r#"{"id":1,"type":"ANIME","title":{}}"#));
        assert_eq!(none.title.romaji, "Tanpa judul");
    }

    #[test]
    fn adult_entries_are_dropped_from_visible_lists() {
        let items = vec![
            raw(r#"{"id":1,"type":"ANIME","title":{"romaji":"A"},"isAdult":false}"#),
            raw(r#"{"id":2,"type":"ANIME","title":{"romaji":"B"},"isAdult":true}"#),
            raw(r#"{"id":3,"type":"ANIME","title":{"romaji":"C"}}"#),
        ];
        let ids: Vec<u64> = visible_summaries(items)
            .iter()
            .map(|item| item.id.get())
            .collect();
        assert_eq!(ids, vec![1, 3]);
    }
}
