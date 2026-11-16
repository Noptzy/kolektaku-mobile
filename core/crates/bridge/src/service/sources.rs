use std::time::{Duration, Instant};

use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::SourceId;

use crate::dto::media::MediaKindDto;
use crate::dto::sources::{PingVerdictDto, SourcePingDto, SourceStatusDto};
use crate::error::BridgeError;
use crate::state::AppState;

pub fn status<C: MetadataCatalog>(state: &AppState<C>) -> Vec<SourceStatusDto> {
    let mut statuses = Vec::new();
    for kind in [MediaKind::Anime, MediaKind::Manga, MediaKind::Novel] {
        for source in state.registry.for_kind(kind) {
            let info = source.info();
            statuses.push(SourceStatusDto {
                id: info.id.to_string(),
                name: info.name.clone(),
                kind: MediaKindDto::from(kind),
                enabled: state.switches.is_enabled(&info.id),
                skipped: state.health.is_skipped(&info.id),
                summary: info.summary.clone(),
            });
        }
    }
    statuses
}

pub async fn set_enabled<C: MetadataCatalog>(state: &AppState<C>, id: &str, enabled: bool) {
    let id = SourceId::new(id);
    state
        .switches
        .set_enabled(state.library.as_ref(), &id, enabled)
        .await;
}

const PING_LIMIT: Duration = Duration::from_secs(8);

pub async fn ping<C: MetadataCatalog>(
    state: &AppState<C>,
    id: &str,
) -> Result<SourcePingDto, BridgeError> {
    let source = state
        .registry
        .get(&SourceId::new(id))
        .ok_or_else(|| BridgeError::from(SourceError::NotFound(id.to_string())))?;
    let started = Instant::now();
    let answer = tokio::time::timeout(PING_LIMIT, source.latest(1)).await;
    let millis = started.elapsed().as_millis().min(u128::from(u32::MAX)) as u32;
    let verdict = match &answer {
        Ok(outcome) => match outcome {
            Ok(_) => PingVerdictDto::Online,
            Err(SourceError::MarkupChanged(_) | SourceError::ChallengeRequired(_)) => {
                PingVerdictDto::Changed
            }
            Err(_) => PingVerdictDto::Offline,
        },
        Err(_) => PingVerdictDto::Offline,
    };
    Ok(SourcePingDto {
        id: id.to_string(),
        verdict,
        millis,
    })
}
