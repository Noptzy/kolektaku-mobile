use domain::error::SourceError;
use domain::stream::{
    SkipKind, SkipRange, StreamKind, StreamSet, StreamSource, SubtitleTrack,
};
use serde::Deserialize;
use url::Url;

#[derive(Debug, Deserialize)]
struct RawTrack {
    file: Option<String>,
    label: Option<String>,
    kind: Option<String>,
    #[serde(default)]
    default: bool,
}

#[derive(Debug, Deserialize)]
struct RawMark {
    kind: Option<String>,
    start: Option<f64>,
    end: Option<f64>,
}

#[derive(Debug, Deserialize)]
struct RawPayload {
    origin: Option<String>,
    file: Option<String>,
    image: Option<String>,
    tracks: Option<Vec<RawTrack>>,
    marks: Option<Vec<RawMark>>,
}

fn secure(address: &str) -> Option<String> {
    let url = Url::parse(address.trim()).ok()?;
    (url.scheme() == "https" && url.host_str().is_some()).then(|| url.to_string())
}

fn origin_of(address: &str) -> Option<String> {
    let url = Url::parse(address.trim()).ok()?;
    if url.scheme() != "https" {
        return None;
    }
    Some(url.origin().ascii_serialization())
}

fn subtitles_of(tracks: Option<Vec<RawTrack>>) -> Vec<SubtitleTrack> {
    tracks
        .unwrap_or_default()
        .into_iter()
        .filter(|track| track.kind.as_deref() == Some("captions"))
        .filter_map(|track| {
            let url = secure(track.file.as_deref()?)?;
            let label = track.label.filter(|label| !label.trim().is_empty())?;
            Some(SubtitleTrack::from_label(&label, url, track.default))
        })
        .collect()
}

fn skips_of(marks: Option<Vec<RawMark>>) -> Vec<SkipRange> {
    marks
        .unwrap_or_default()
        .into_iter()
        .filter_map(|mark| {
            let kind = match mark.kind.as_deref()? {
                "intro" => SkipKind::Intro,
                "outro" => SkipKind::Outro,
                _ => return None,
            };
            SkipRange::from_seconds(kind, mark.start?, mark.end?)
        })
        .collect()
}

pub fn parse_stream_payload(payload: &str) -> Result<StreamSet, SourceError> {
    let raw: RawPayload = serde_json::from_str(payload)
        .map_err(|error| SourceError::MarkupChanged(format!("stream payload is invalid: {error}")))?;
    let file = raw
        .file
        .as_deref()
        .and_then(secure)
        .ok_or_else(|| SourceError::MarkupChanged("the player gave no stream address".into()))?;
    let kind = if file.contains(".m3u8") {
        StreamKind::Hls
    } else {
        StreamKind::Mp4
    };
    let source = StreamSource {
        url: file,
        kind,
        quality: 0,
        label: "Otomatis".into(),
        is_default: true,
    };
    let headers = raw
        .origin
        .as_deref()
        .and_then(origin_of)
        .map(|origin| {
            vec![
                ("referer".to_string(), format!("{origin}/")),
                ("origin".to_string(), origin),
            ]
        })
        .unwrap_or_default();
    let poster = raw.image.as_deref().and_then(secure);
    let set = StreamSet::from_sources(vec![source], poster)
        .ok_or_else(|| SourceError::MarkupChanged("the player gave no stream".into()))?;
    Ok(set
        .with_headers(headers)
        .with_subtitles(subtitles_of(raw.tracks))
        .with_skips(skips_of(raw.marks)))
}
