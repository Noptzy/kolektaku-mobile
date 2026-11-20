use domain::error::SourceError;
use domain::settings::QualityPreference;
use domain::stream::{StreamKind, StreamSet, StreamSource};
use url::Url;

use super::hls::{
    MediaPlaylist, choose_audio, choose_variant, is_master, parse_master, parse_media,
};
use crate::http::{HttpClient, HttpRequest};

const FALLBACK_RESOLUTION: (u32, u32) = (1280, 720);

#[derive(Debug, Clone, PartialEq)]
pub enum MediaPlan {
    Hls {
        video: MediaPlaylist,
        audio: Option<MediaPlaylist>,
        resolution: (u32, u32),
    },
    File {
        url: String,
    },
}

fn pick_source(set: &StreamSet, quality: QualityPreference) -> Option<&StreamSource> {
    if let Some(hls) = set
        .sources
        .iter()
        .find(|source| source.kind == StreamKind::Hls)
    {
        return Some(hls);
    }
    let ceiling = quality.max_height().unwrap_or(u32::MAX);
    set.sources
        .iter()
        .filter(|source| source.quality == 0 || source.quality <= ceiling)
        .max_by_key(|source| source.quality)
        .or_else(|| set.sources.iter().min_by_key(|source| source.quality))
}

async fn text(
    http: &dyn HttpClient,
    url: &str,
    headers: &[(String, String)],
) -> Result<String, SourceError> {
    let request = headers
        .iter()
        .fold(HttpRequest::get(url), |request, (name, value)| {
            request.with_header(name, value)
        });
    let response = http.send(request).await?;
    if !response.is_success() {
        return Err(SourceError::Unavailable(format!(
            "the playlist answered {}",
            response.status
        )));
    }
    Ok(response.body)
}

fn address(url: &str) -> Result<Url, SourceError> {
    Url::parse(url).map_err(|_| SourceError::MarkupChanged(format!("bad playlist address {url}")))
}

async fn media(
    http: &dyn HttpClient,
    url: &str,
    headers: &[(String, String)],
) -> Result<MediaPlaylist, SourceError> {
    parse_media(&text(http, url, headers).await?, &address(url)?)
}

pub async fn plan_media(
    http: &dyn HttpClient,
    set: &StreamSet,
    quality: QualityPreference,
) -> Result<MediaPlan, SourceError> {
    let source = pick_source(set, quality)
        .ok_or_else(|| SourceError::NotFound("this episode has no video".into()))?;
    if source.kind == StreamKind::Mp4 {
        return Ok(MediaPlan::File {
            url: source.url.clone(),
        });
    }
    let headers = &set.headers;
    let first = text(http, &source.url, headers).await?;
    if !is_master(&first) {
        let video = parse_media(&first, &address(&source.url)?)?;
        return Ok(MediaPlan::Hls {
            video,
            audio: None,
            resolution: FALLBACK_RESOLUTION,
        });
    }
    let master = parse_master(&first, &address(&source.url)?);
    let variant = choose_variant(&master.variants, quality.max_height())
        .ok_or_else(|| SourceError::MarkupChanged("the playlist lists no pictures".into()))?;
    let video = media(http, &variant.url, headers).await?;
    let audio = match choose_audio(&master.audio, variant.audio_group.as_deref())
        .and_then(|r| r.url.clone())
    {
        Some(url) => Some(media(http, &url, headers).await?),
        None => None,
    };
    let resolution = match (variant.width, variant.height) {
        (Some(width), Some(height)) => (width, height),
        _ => FALLBACK_RESOLUTION,
    };
    Ok(MediaPlan::Hls {
        video,
        audio,
        resolution,
    })
}
