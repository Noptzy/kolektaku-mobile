use application::reading::ChapterView;
use application::streaming::Playback;
use domain::stream::{EpisodeServer, StreamPlan, StreamSet, StreamSource};

use super::media::tag;
use super::sources::UnitDto;
pub use super::stream_extras::{SkipDto, SubtitleDto};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ServerDto {
    pub id: String,
    pub label: String,
    pub variant: Option<String>,
    pub audio: Option<String>,
}

impl From<&EpisodeServer> for ServerDto {
    fn from(server: &EpisodeServer) -> Self {
        Self {
            id: server.id.clone(),
            label: server.label.clone(),
            variant: server.variant.map(|variant| variant.key().to_string()),
            audio: server.audio.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct PlaybackDto {
    pub source: String,
    pub item: String,
    pub unit: UnitDto,
    pub servers: Vec<ServerDto>,
    pub switched_from: Option<String>,
}

impl From<&Playback> for PlaybackDto {
    fn from(playback: &Playback) -> Self {
        Self {
            source: playback.source.to_string(),
            item: playback.item.to_string(),
            unit: (&playback.unit).into(),
            servers: playback.servers.iter().map(Into::into).collect(),
            switched_from: playback.switched_from.as_ref().map(ToString::to_string),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StreamSourceDto {
    pub url: String,
    pub kind: String,
    pub quality: u32,
    pub label: String,
    pub is_default: bool,
}

impl From<&StreamSource> for StreamSourceDto {
    fn from(source: &StreamSource) -> Self {
        Self {
            url: source.url.clone(),
            kind: tag(&source.kind),
            quality: source.quality,
            label: source.label.clone(),
            is_default: source.is_default,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StreamSetDto {
    pub sources: Vec<StreamSourceDto>,
    pub poster_url: Option<String>,
    pub headers: Vec<HeaderDto>,
    pub subtitles: Vec<SubtitleDto>,
    pub skips: Vec<SkipDto>,
}

impl From<&StreamSet> for StreamSetDto {
    fn from(set: &StreamSet) -> Self {
        Self {
            sources: set.sources.iter().map(Into::into).collect(),
            poster_url: set.poster_url.clone(),
            headers: set
                .headers
                .iter()
                .map(|(name, value)| HeaderDto {
                    name: name.clone(),
                    value: value.clone(),
                })
                .collect(),
            subtitles: set.subtitles.iter().map(Into::into).collect(),
            skips: set.skips.iter().map(Into::into).collect(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HeaderDto {
    pub name: String,
    pub value: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StreamPlanKind {
    Direct,
    NeedsWebView,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct StreamPlanDto {
    pub kind: StreamPlanKind,
    pub sources: Vec<StreamSourceDto>,
    pub headers: Vec<HeaderDto>,
    pub url: String,
    pub script: String,
    pub allowed_host: String,
}

impl From<&StreamPlan> for StreamPlanDto {
    fn from(plan: &StreamPlan) -> Self {
        match plan {
            StreamPlan::Direct { sources, headers } => Self {
                kind: StreamPlanKind::Direct,
                sources: sources.iter().map(Into::into).collect(),
                headers: headers
                    .iter()
                    .map(|(name, value)| HeaderDto {
                        name: name.clone(),
                        value: value.clone(),
                    })
                    .collect(),
                url: String::new(),
                script: String::new(),
                allowed_host: String::new(),
            },
            StreamPlan::NeedsWebView {
                url,
                script,
                allowed_host,
            } => Self {
                kind: StreamPlanKind::NeedsWebView,
                sources: Vec::new(),
                headers: Vec::new(),
                url: url.clone(),
                script: script.clone(),
                allowed_host: allowed_host.clone(),
            },
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct ChapterViewDto {
    pub source: String,
    pub item: String,
    pub unit: UnitDto,
    pub pages: Vec<String>,
    pub switched_from: Option<String>,
}

impl From<&ChapterView> for ChapterViewDto {
    fn from(view: &ChapterView) -> Self {
        Self {
            source: view.source.to_string(),
            item: view.item.to_string(),
            unit: (&view.unit).into(),
            pages: view
                .pages
                .pages
                .iter()
                .map(|page| page.url.clone())
                .collect(),
            switched_from: view.switched_from.as_ref().map(ToString::to_string),
        }
    }
}
