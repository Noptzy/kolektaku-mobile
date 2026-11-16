use application::ports::MetadataCatalog;
use domain::media::MediaKind;
use domain::source::SourceId;

use crate::dto::media::MediaKindDto;
use crate::dto::sources::SourceStatusDto;
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
