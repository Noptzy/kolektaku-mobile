use domain::error::SourceError;
use domain::stream::{StreamKind, StreamSet, StreamSource};
use serde::Deserialize;
use serde_json::Value;
use url::Url;

use super::quality::parse_quality;

#[derive(Deserialize)]
struct Payload {
    poster: Option<String>,
    sources: Vec<PayloadSource>,
}

#[derive(Deserialize)]
struct PayloadSource {
    url: String,
    #[serde(rename = "type")]
    mime: Option<String>,
    quality: Option<Value>,
}

fn quality_text(value: Option<&Value>) -> String {
    match value {
        Some(Value::String(text)) => text.clone(),
        Some(Value::Number(number)) => number.to_string(),
        _ => String::new(),
    }
}

fn stream_kind(url: &Url, mime: &str) -> StreamKind {
    if mime.to_lowercase().contains("mpegurl") || url.path().to_lowercase().ends_with(".m3u8") {
        StreamKind::Hls
    } else {
        StreamKind::Mp4
    }
}

fn read_source(source: PayloadSource) -> Option<StreamSource> {
    let url = Url::parse(&source.url)
        .ok()
        .filter(|url| matches!(url.scheme(), "http" | "https"))?;
    let quality = parse_quality(&[&quality_text(source.quality.as_ref())], url.as_str())?;
    Some(StreamSource {
        url: url.to_string(),
        kind: stream_kind(&url, source.mime.as_deref().unwrap_or_default()),
        quality: quality.value,
        label: quality.label,
        is_default: false,
    })
}

pub fn parse_stream_payload(payload: &str) -> Result<StreamSet, SourceError> {
    let parsed: Payload = serde_json::from_str(payload).map_err(|error| {
        SourceError::MarkupChanged(format!("stream payload is invalid: {error}"))
    })?;
    let poster = parsed
        .poster
        .map(|poster| poster.trim().to_string())
        .filter(|poster| !poster.is_empty());
    let sources = parsed.sources.into_iter().filter_map(read_source).collect();
    StreamSet::from_sources(sources, poster)
        .ok_or_else(|| SourceError::MarkupChanged("playable stream sources were not found".into()))
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::*;
    use crate::fixtures;

    #[test]
    fn returns_the_sources_best_quality_first_with_the_poster() {
        let set = parse_stream_payload(&fixtures::kuramanime("stream-payload.json")).unwrap();
        let summary: Vec<(u32, &str, bool)> = set
            .sources
            .iter()
            .map(|source| (source.quality, source.label.as_str(), source.is_default))
            .collect();
        assert_eq!(
            summary,
            vec![
                (720, "720p", true),
                (480, "480p", false),
                (360, "360p", false)
            ]
        );
        assert_eq!(
            set.poster_url.as_deref(),
            Some("https://img.example/one-piece.jpg")
        );
        assert!(
            set.sources
                .iter()
                .all(|source| source.kind == StreamKind::Mp4)
        );
    }

    #[test]
    fn detects_hls_by_mime_type_or_by_extension() {
        let payload = json!({"poster": "", "sources": [
            {"url": "https://cdn.example/master.m3u8", "type": "application/x-mpegURL", "quality": "1080"},
            {"url": "https://cdn.example/a.MP4", "type": "application/vnd.apple.mpegurl", "quality": 720},
            {"url": "https://cdn.example/b.m3u8", "type": "", "quality": "480"},
        ]});
        let set = parse_stream_payload(&payload.to_string()).unwrap();
        assert!(
            set.sources
                .iter()
                .all(|source| source.kind == StreamKind::Hls)
        );
        assert_eq!(set.poster_url, None);
    }

    #[test]
    fn keeps_every_scraped_quality_without_a_cap() {
        let payload = json!({"sources": [
            {"url": "https://cdn.example/anime-4k.mp4", "type": "video/mp4", "quality": "4K"},
            {"url": "https://cdn.example/anime-1440.mp4", "type": "video/mp4", "quality": "1440"},
            {"url": "https://cdn.example/anime-fullhd.mp4", "type": "video/mp4", "quality": "1080p"},
            {"url": "https://cdn.example/anime-720.mp4", "type": "video/mp4", "quality": ""},
        ]});
        let set = parse_stream_payload(&payload.to_string()).unwrap();
        let summary: Vec<(u32, &str)> = set
            .sources
            .iter()
            .map(|s| (s.quality, s.label.as_str()))
            .collect();
        assert_eq!(
            summary,
            vec![
                (2160, "4K"),
                (1440, "1440p"),
                (1080, "1080p"),
                (720, "720p")
            ]
        );
    }

    #[test]
    fn sources_that_are_not_web_urls_or_have_no_quality_are_dropped() {
        let payload = json!({"sources": [
            {"url": "javascript:alert(1)", "quality": "720"},
            {"url": "file:///sdcard/a.mp4", "quality": "720"},
            {"url": "https://cdn.example/noquality.mp4", "quality": ""},
            {"url": "https://cdn.example/ok-480.mp4", "quality": ""},
        ]});
        let set = parse_stream_payload(&payload.to_string()).unwrap();
        assert_eq!(set.sources.len(), 1);
        assert_eq!(set.sources[0].quality, 480);
    }

    #[test]
    fn nothing_playable_or_broken_json_is_a_markup_change() {
        for payload in [
            r#"{"sources":[]}"#,
            "not json",
            r#"{"poster":"x"}"#,
            r#"{"sources":[{"url":"https://x.test/a.mp4"}]}"#,
        ] {
            assert!(
                matches!(
                    parse_stream_payload(payload),
                    Err(SourceError::MarkupChanged(_))
                ),
                "{payload}"
            );
        }
    }
}
