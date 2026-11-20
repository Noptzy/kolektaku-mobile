use domain::stream::{SkipRange, StreamSet, StreamSource, SubtitleTrack};
use serde::de::DeserializeOwned;

use super::stream::{StreamSetDto, StreamSourceDto};
use super::stream_extras::{SkipDto, SubtitleDto};

fn untag<T: DeserializeOwned>(text: &str) -> Option<T> {
    serde_json::from_value(serde_json::Value::String(text.to_string())).ok()
}

fn source(dto: &StreamSourceDto) -> Option<StreamSource> {
    Some(StreamSource {
        url: dto.url.clone(),
        kind: untag(&dto.kind)?,
        quality: dto.quality,
        label: dto.label.clone(),
        is_default: dto.is_default,
    })
}

fn subtitle(dto: &SubtitleDto) -> Option<SubtitleTrack> {
    Some(SubtitleTrack {
        label: dto.label.clone(),
        language: dto.language.clone(),
        variant: untag(&dto.variant)?,
        url: dto.url.clone(),
        is_default: dto.is_default,
    })
}

fn skip(dto: &SkipDto) -> Option<SkipRange> {
    Some(SkipRange {
        kind: untag(&dto.kind)?,
        start_ms: dto.start_ms,
        end_ms: dto.end_ms,
    })
}

pub fn stream_set_from(dto: &StreamSetDto) -> StreamSet {
    StreamSet {
        sources: dto.sources.iter().filter_map(source).collect(),
        poster_url: dto.poster_url.clone(),
        headers: dto
            .headers
            .iter()
            .map(|header| (header.name.clone(), header.value.clone()))
            .collect(),
        subtitles: dto.subtitles.iter().filter_map(subtitle).collect(),
        skips: dto.skips.iter().filter_map(skip).collect(),
    }
}

#[cfg(test)]
mod tests {
    use domain::stream::{SkipKind, StreamKind, SubtitleVariant};

    use super::*;

    fn domain_set() -> StreamSet {
        StreamSet {
            sources: vec![StreamSource {
                url: "https://hls.test/master.m3u8".into(),
                kind: StreamKind::Hls,
                quality: 720,
                label: "720p".into(),
                is_default: true,
            }],
            poster_url: Some("https://img.test/p.jpg".into()),
            headers: vec![("referer".into(), "https://site.test/".into())],
            subtitles: vec![SubtitleTrack {
                label: "English".into(),
                language: Some("en".into()),
                variant: SubtitleVariant::Forced,
                url: "https://subs.test/en.vtt".into(),
                is_default: false,
            }],
            skips: vec![SkipRange {
                kind: SkipKind::Intro,
                start_ms: 1,
                end_ms: 2,
            }],
        }
    }

    #[test]
    fn a_stream_sent_back_from_the_app_matches_the_one_it_was_given() {
        let original = domain_set();
        let dto = StreamSetDto::from(&original);
        assert_eq!(stream_set_from(&dto), original);
    }

    #[test]
    fn an_unknown_kind_drops_only_that_entry() {
        let mut dto = StreamSetDto::from(&domain_set());
        dto.sources[0].kind = "dash".into();
        assert!(stream_set_from(&dto).sources.is_empty());
        assert_eq!(stream_set_from(&dto).subtitles.len(), 1);
    }
}
