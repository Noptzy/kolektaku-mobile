use domain::stream::{SkipRange, SubtitleTrack};

use super::media::tag;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SubtitleDto {
    pub label: String,
    pub language: Option<String>,
    pub variant: String,
    pub url: String,
    pub is_default: bool,
}

impl From<&SubtitleTrack> for SubtitleDto {
    fn from(track: &SubtitleTrack) -> Self {
        Self {
            label: track.label.clone(),
            language: track.language.clone(),
            variant: tag(&track.variant),
            url: track.url.clone(),
            is_default: track.is_default,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SkipDto {
    pub kind: String,
    pub start_ms: u64,
    pub end_ms: u64,
}

impl From<&SkipRange> for SkipDto {
    fn from(range: &SkipRange) -> Self {
        Self {
            kind: tag(&range.kind),
            start_ms: range.start_ms,
            end_ms: range.end_ms,
        }
    }
}
