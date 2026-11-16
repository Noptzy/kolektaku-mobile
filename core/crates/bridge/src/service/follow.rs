use application::ports::MetadataCatalog;
use application::updates::CheckUpdates;

use crate::dto::follow::UpdateEventDto;
use crate::state::AppState;

pub async fn check_followed<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
) -> Vec<UpdateEventDto> {
    let check = CheckUpdates::new(
        state.library.clone(),
        state.links.clone(),
        state.updates.clone(),
        state.directory.clone(),
        state.health.clone(),
        state.clock.clone(),
    );
    check
        .execute()
        .await
        .iter()
        .map(UpdateEventDto::from)
        .collect()
}
