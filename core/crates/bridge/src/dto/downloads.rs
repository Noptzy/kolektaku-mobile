use domain::download::{
    DownloadJob, DownloadPhase, DownloadSettings, DownloadSubtitles, DownloadTarget,
};
use domain::settings::QualityPreference;

use super::media::{MediaKindDto, MediaRefDto};
use crate::error::BridgeError;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DownloadPhaseDto {
    Queued,
    Fetching,
    Subtitles,
    Muxing,
    Done,
    Failed,
    Cancelled,
}

impl From<DownloadPhase> for DownloadPhaseDto {
    fn from(phase: DownloadPhase) -> Self {
        match phase {
            DownloadPhase::Queued => Self::Queued,
            DownloadPhase::Fetching => Self::Fetching,
            DownloadPhase::Subtitles => Self::Subtitles,
            DownloadPhase::Muxing => Self::Muxing,
            DownloadPhase::Done => Self::Done,
            DownloadPhase::Failed => Self::Failed,
            DownloadPhase::Cancelled => Self::Cancelled,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct DownloadTargetDto {
    pub reference: MediaRefDto,
    pub kind: MediaKindDto,
    pub title: String,
    pub episode: f64,
    pub cover_url: Option<String>,
}

impl DownloadTargetDto {
    pub fn to_domain(&self) -> Result<DownloadTarget, BridgeError> {
        Ok(DownloadTarget {
            media: self.reference.require()?,
            kind: self.kind.into(),
            title: self.title.clone(),
            episode: self.episode,
            cover_url: self.cover_url.clone(),
        })
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct DownloadDto {
    pub id: i64,
    pub target: DownloadTargetDto,
    pub phase: DownloadPhaseDto,
    pub progress: f32,
    pub bytes: u64,
    pub file_path: Option<String>,
    pub error: Option<String>,
    pub interrupted: bool,
}

impl From<&DownloadJob> for DownloadDto {
    fn from(job: &DownloadJob) -> Self {
        Self {
            id: job.id,
            target: DownloadTargetDto {
                reference: (&job.target.media).into(),
                kind: job.target.kind.into(),
                title: job.target.title.clone(),
                episode: job.target.episode,
                cover_url: job.target.cover_url.clone(),
            },
            phase: job.phase.into(),
            progress: job.progress,
            bytes: job.bytes,
            file_path: job.file_path.clone(),
            error: job.error.clone(),
            interrupted: job.error.as_deref() == Some(application::downloads::INTERRUPTED),
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DownloadSubtitlesDto {
    Translated,
    Original,
    Off,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DownloadSettingsDto {
    pub subtitles: DownloadSubtitlesDto,
    pub quality: String,
}

impl From<DownloadSettings> for DownloadSettingsDto {
    fn from(settings: DownloadSettings) -> Self {
        Self {
            subtitles: match settings.subtitles {
                DownloadSubtitles::Translated => DownloadSubtitlesDto::Translated,
                DownloadSubtitles::Original => DownloadSubtitlesDto::Original,
                DownloadSubtitles::Off => DownloadSubtitlesDto::Off,
            },
            quality: settings.quality.key().to_string(),
        }
    }
}

impl DownloadSettingsDto {
    pub fn to_domain(&self) -> DownloadSettings {
        let fallback = DownloadSettings::default();
        DownloadSettings {
            subtitles: match self.subtitles {
                DownloadSubtitlesDto::Translated => DownloadSubtitles::Translated,
                DownloadSubtitlesDto::Original => DownloadSubtitles::Original,
                DownloadSubtitlesDto::Off => DownloadSubtitles::Off,
            },
            quality: QualityPreference::parse(&self.quality).unwrap_or(fallback.quality),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn settings_round_trip_and_an_unknown_quality_falls_back() {
        let settings = DownloadSettings {
            subtitles: DownloadSubtitles::Off,
            quality: QualityPreference::P1080,
        };
        assert_eq!(DownloadSettingsDto::from(settings).to_domain(), settings);
        let odd = DownloadSettingsDto {
            subtitles: DownloadSubtitlesDto::Original,
            quality: "8k".into(),
        };
        assert_eq!(odd.to_domain().quality, QualityPreference::P720);
    }

    #[test]
    fn every_phase_has_its_own_value() {
        assert_eq!(
            DownloadPhaseDto::from(DownloadPhase::Muxing),
            DownloadPhaseDto::Muxing
        );
        assert_eq!(
            DownloadPhaseDto::from(DownloadPhase::Cancelled),
            DownloadPhaseDto::Cancelled
        );
    }

    #[test]
    fn a_target_with_a_broken_reference_is_refused() {
        let target = DownloadTargetDto {
            reference: MediaRefDto::site("", ""),
            kind: MediaKindDto::Anime,
            title: "A".into(),
            episode: 1.0,
            cover_url: None,
        };
        assert!(target.to_domain().is_err());
    }
}
