use application::library::ContinueList;
use application::ports::MetadataCatalog;
use domain::library::LibraryRepository;

use crate::dto::library::{FavoriteDto, ProgressDto, UnitOrderDto};
use crate::dto::media::{MediaKindDto, MediaRefDto};
use crate::error::BridgeError;
use crate::state::AppState;

pub async fn favorites<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<Vec<FavoriteDto>, BridgeError> {
    let found = state.library.favorites(kind.into()).await?;
    Ok(found.iter().map(Into::into).collect())
}

pub async fn is_favorite<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
) -> Result<bool, BridgeError> {
    let reference = target.require()?;
    Ok(state.library.is_favorite(kind.into(), &reference).await?)
}

pub async fn toggle_favorite<C: MetadataCatalog>(
    state: &AppState<C>,
    favorite: FavoriteDto,
) -> Result<bool, BridgeError> {
    let input = favorite
        .to_input()
        .ok_or_else(|| BridgeError::not_found("invalid reference"))?;
    Ok(state.library.toggle_favorite(input).await?)
}

pub async fn history<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<Vec<ProgressDto>, BridgeError> {
    let found = state.library.history(kind.into()).await?;
    Ok(found.iter().map(Into::into).collect())
}

pub async fn continue_list<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<Vec<ProgressDto>, BridgeError> {
    let found = ContinueList::new(state.library.clone())
        .execute(kind.into())
        .await?;
    Ok(found.iter().map(Into::into).collect())
}

pub async fn save_progress<C: MetadataCatalog>(
    state: &AppState<C>,
    progress: ProgressDto,
) -> Result<(), BridgeError> {
    let input = progress
        .to_input()
        .ok_or_else(|| BridgeError::not_found("invalid reference"))?;
    Ok(state.library.save_progress(input).await?)
}

pub async fn progress_for<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
    unit_number: f64,
) -> Result<Option<ProgressDto>, BridgeError> {
    let reference = target.require()?;
    let found = state
        .library
        .progress_for(kind.into(), &reference, unit_number)
        .await?;
    Ok(found.as_ref().map(Into::into))
}

pub async fn last_progress<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
) -> Result<Option<ProgressDto>, BridgeError> {
    let reference = target.require()?;
    let found = state.library.last_progress(kind.into(), &reference).await?;
    Ok(found.as_ref().map(Into::into))
}

pub async fn remove_progress<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
    unit_number: f64,
) -> Result<(), BridgeError> {
    let reference = target.require()?;
    Ok(state
        .library
        .remove_progress(kind.into(), &reference, unit_number)
        .await?)
}

pub async fn clear_history<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<(), BridgeError> {
    Ok(state.library.clear_history(kind.into()).await?)
}

pub async fn unit_order<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
) -> Result<UnitOrderDto, BridgeError> {
    let reference = target.require()?;
    Ok(state
        .library
        .unit_order(kind.into(), &reference)
        .await?
        .into())
}

pub async fn set_unit_order<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
    order: UnitOrderDto,
) -> Result<(), BridgeError> {
    let reference = target.require()?;
    Ok(state
        .library
        .set_unit_order(kind.into(), &reference, order.into())
        .await?)
}

pub async fn searches<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<Vec<String>, BridgeError> {
    Ok(state.library.searches(kind.into()).await?)
}

pub async fn add_search<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
    query: &str,
) -> Result<(), BridgeError> {
    Ok(state.library.add_search(kind.into(), query).await?)
}

pub async fn clear_searches<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<(), BridgeError> {
    Ok(state.library.clear_searches(kind.into()).await?)
}

pub async fn preference<C: MetadataCatalog>(
    state: &AppState<C>,
    name: &str,
) -> Result<Option<String>, BridgeError> {
    Ok(state.library.preference(name).await?)
}

pub async fn set_preference<C: MetadataCatalog>(
    state: &AppState<C>,
    name: &str,
    value: &str,
) -> Result<(), BridgeError> {
    Ok(state.library.set_preference(name, value).await?)
}
