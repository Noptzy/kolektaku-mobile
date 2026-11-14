use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, Deserialize)]
pub struct RawAnime {
    #[serde(rename = "_id")]
    pub id: Option<String>,
    pub title: Option<String>,
    #[serde(rename = "alternateTitle")]
    pub alternate_title: Option<String>,
    #[serde(rename = "English")]
    pub english: Option<String>,
    #[serde(rename = "Japanese")]
    pub japanese: Option<String>,
    pub slug: Option<String>,
    pub slugs: Option<Vec<String>>,
    pub mal_id: Option<Value>,
    #[serde(rename = "createdAt")]
    pub created_at: Option<String>,
    pub image: Option<String>,
    pub synopsis: Option<String>,
    pub genres: Option<Vec<String>>,
    #[serde(rename = "Type")]
    pub kind: Option<String>,
    #[serde(rename = "totalEpisodes")]
    pub total_episodes: Option<Value>,
    #[serde(rename = "totalSubbed")]
    pub total_subbed: Option<Value>,
    #[serde(rename = "Aired")]
    pub aired: Option<String>,
    #[serde(rename = "Rating")]
    pub rating: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RawFilter {
    pub results: Option<Vec<RawAnime>>,
    #[serde(rename = "totalPages")]
    pub total_pages: Option<u32>,
}

#[derive(Debug, Deserialize)]
pub struct RawLatest {
    pub animes: Option<Vec<RawAnime>>,
    #[serde(rename = "totalPages")]
    pub total_pages: Option<u32>,
}

#[derive(Debug, Deserialize)]
pub struct RawDetail {
    pub anime: RawAnime,
}

#[derive(Debug, Deserialize)]
pub struct RawLinks {
    pub sub: Option<Vec<String>>,
    pub dub: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct RawEpisode {
    #[serde(rename = "episodeNumber")]
    pub number: Option<f64>,
    pub slug: Option<String>,
    pub link: Option<RawLinks>,
}

#[derive(Debug, Deserialize)]
pub struct RawEpisodes {
    pub total: Option<u32>,
    pub episodes: Option<Vec<RawEpisode>>,
}

#[derive(Debug, Deserialize)]
pub struct RawEpisodeResponse {
    pub episode: RawEpisode,
}

pub fn number_of(value: &Value) -> Option<u32> {
    match value {
        Value::Number(number) => number.as_u64().and_then(|n| u32::try_from(n).ok()),
        Value::String(text) => text.trim().parse().ok(),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::*;

    #[test]
    fn counts_may_arrive_as_numbers_or_text() {
        assert_eq!(number_of(&json!(8)), Some(8));
        assert_eq!(number_of(&json!("12")), Some(12));
        assert_eq!(number_of(&json!(" 3 ")), Some(3));
        assert_eq!(number_of(&json!("banyak")), None);
        assert_eq!(number_of(&json!(null)), None);
        assert_eq!(number_of(&json!(-1)), None);
    }

    #[test]
    fn an_entry_with_few_fields_still_parses() {
        let anime: RawAnime = serde_json::from_str(r#"{"title":"X"}"#).unwrap();
        assert_eq!(anime.title.as_deref(), Some("X"));
        assert!(anime.slug.is_none() && anime.id.is_none());
    }

    #[test]
    fn the_site_field_names_are_read() {
        let raw = r#"{"_id":"a","English":"E","Japanese":"J","Type":"TV","totalEpisodes":"8","Aired":"2026"}"#;
        let anime: RawAnime = serde_json::from_str(raw).unwrap();
        assert_eq!(anime.id.as_deref(), Some("a"));
        assert_eq!(anime.english.as_deref(), Some("E"));
        assert_eq!(anime.kind.as_deref(), Some("TV"));
        assert_eq!(number_of(anime.total_episodes.as_ref().unwrap()), Some(8));
    }
}
