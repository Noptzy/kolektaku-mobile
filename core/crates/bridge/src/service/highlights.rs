use application::ports::MetadataCatalog;
use domain::highlight::HighlightStore;

use crate::dto::highlight::{HighlightDto, HighlightInputDto};
use crate::dto::media::MediaRefDto;
use crate::error::BridgeError;
use crate::state::AppState;

pub async fn add<C: MetadataCatalog>(
    state: &AppState<C>,
    input: &HighlightInputDto,
) -> Result<i64, BridgeError> {
    let now = state.clock.now_secs();
    Ok(state.highlights.add(input.to_domain()?, now).await?)
}

pub async fn remove<C: MetadataCatalog>(state: &AppState<C>, id: i64) -> Result<(), BridgeError> {
    Ok(state.highlights.remove(id).await?)
}

pub async fn for_chapter<C: MetadataCatalog>(
    state: &AppState<C>,
    reference: &MediaRefDto,
    chapter: f64,
) -> Result<Vec<HighlightDto>, BridgeError> {
    let found = state
        .highlights
        .for_chapter(&reference.require()?, chapter)
        .await?;
    Ok(found.iter().map(HighlightDto::from).collect())
}

pub async fn all<C: MetadataCatalog>(
    state: &AppState<C>,
) -> Result<Vec<HighlightDto>, BridgeError> {
    let found = state.highlights.all().await?;
    Ok(found.iter().map(HighlightDto::from).collect())
}
