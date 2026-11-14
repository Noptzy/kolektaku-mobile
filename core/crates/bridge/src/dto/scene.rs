use application::scene::{DetailReason, SceneFinding, SceneOutcome, SceneTarget};
use domain::media::MediaId;
use domain::scene::SceneMatch;

use crate::error::BridgeError;

#[derive(Debug, Clone, PartialEq)]
pub struct SceneMatchDto {
    pub media_id: u64,
    pub episode: Option<f64>,
    pub from_secs: f64,
    pub at_secs: f64,
    pub to_secs: f64,
    pub similarity: f32,
    pub preview_image_url: Option<String>,
    pub title: Option<String>,
    pub duration_secs: Option<f64>,
}

impl From<&SceneMatch> for SceneMatchDto {
    fn from(found: &SceneMatch) -> Self {
        Self {
            media_id: found.media_id.get(),
            episode: found.episode,
            from_secs: found.from_secs,
            at_secs: found.at_secs,
            to_secs: found.to_secs,
            similarity: found.similarity,
            preview_image_url: found.preview_image_url.clone(),
            title: found.title.clone(),
            duration_secs: found.duration_secs,
        }
    }
}

impl SceneMatchDto {
    pub fn into_domain(&self) -> Result<SceneMatch, BridgeError> {
        let media_id = MediaId::new(self.media_id)
            .ok_or_else(|| BridgeError::not_found("the scene points at no title"))?;
        Ok(SceneMatch {
            media_id,
            episode: self.episode,
            from_secs: self.from_secs,
            at_secs: self.at_secs,
            to_secs: self.to_secs,
            similarity: self.similarity,
            preview_image_url: self.preview_image_url.clone(),
            title: self.title.clone(),
            is_adult: false,
            duration_secs: self.duration_secs,
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SceneOutcomeKind {
    Direct,
    Candidates,
    NotFound,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SceneFindingDto {
    pub kind: SceneOutcomeKind,
    pub best: Option<SceneMatchDto>,
    pub candidates: Vec<SceneMatchDto>,
    pub quota_left: Option<u32>,
}

fn many(matches: &[SceneMatch]) -> Vec<SceneMatchDto> {
    matches.iter().map(SceneMatchDto::from).collect()
}

impl From<&SceneFinding> for SceneFindingDto {
    fn from(finding: &SceneFinding) -> Self {
        let (kind, best, candidates) = match &finding.outcome {
            SceneOutcome::Direct { best, others } => (
                SceneOutcomeKind::Direct,
                Some(SceneMatchDto::from(best)),
                many(others),
            ),
            SceneOutcome::Candidates(list) => (SceneOutcomeKind::Candidates, None, many(list)),
            SceneOutcome::NotFound => (SceneOutcomeKind::NotFound, None, Vec::new()),
        };
        Self {
            kind,
            best,
            candidates,
            quota_left: finding.quota_left,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SceneTargetKind {
    Watch,
    Detail,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DetailReasonDto {
    NotAvailable,
    NoEpisode,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SceneTargetDto {
    pub kind: SceneTargetKind,
    pub media_id: u64,
    pub episode: Option<f64>,
    pub start_secs: Option<f64>,
    pub duration_secs: Option<f64>,
    pub reason: Option<DetailReasonDto>,
}

impl From<&SceneTarget> for SceneTargetDto {
    fn from(target: &SceneTarget) -> Self {
        match target {
            SceneTarget::Watch {
                media,
                episode,
                start_secs,
                duration_secs,
            } => Self {
                kind: SceneTargetKind::Watch,
                media_id: media.get(),
                episode: Some(*episode),
                start_secs: Some(*start_secs),
                duration_secs: *duration_secs,
                reason: None,
            },
            SceneTarget::Detail { media, reason } => Self {
                kind: SceneTargetKind::Detail,
                media_id: media.get(),
                episode: None,
                start_secs: None,
                duration_secs: None,
                reason: Some(match reason {
                    DetailReason::NotAvailable => DetailReasonDto::NotAvailable,
                    DetailReason::NoEpisode => DetailReasonDto::NoEpisode,
                }),
            },
        }
    }
}
