use application::detail::{ListUnits, MediaViewer};
use application::ports::MetadataCatalog;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceId};

use crate::dto::media::{MediaKindDto, MediaRefDto};
use crate::dto::sources::{DetailViewDto, SourceLinkDto, UnitsDto, links_dto, view_dto};
use crate::error::BridgeError;
use crate::state::AppState;

pub async fn media_detail<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
) -> Result<DetailViewDto, BridgeError> {
    let kind: MediaKind = kind.into();
    let resolver = std::sync::Arc::new(state.resolver(kind));
    let viewer = MediaViewer::new(state.catalog.clone(), resolver, state.directory.clone());
    let view = viewer.execute(kind, &target.require()?).await?;
    Ok(view_dto(&view, &state.directory))
}

pub async fn units<C: MetadataCatalog>(
    state: &AppState<C>,
    target: &MediaRefDto,
    source: Option<String>,
) -> Result<UnitsDto, BridgeError> {
    let list = ListUnits::new(
        state.links.clone(),
        state.directory.clone(),
        state.health.clone(),
    );
    let source = source.map(SourceId::new);
    let view = list.execute(&target.require()?, source.as_ref()).await?;
    Ok(UnitsDto::from(&view))
}

pub async fn select_source<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
    source: &str,
    item: &str,
) -> Result<Vec<SourceLinkDto>, BridgeError> {
    let resolver = state.resolver(kind.into());
    let resolved = resolver
        .choose(&target.require()?, SourceId::new(source), ItemId::new(item))
        .await?;
    Ok(links_dto(&resolved, &state.directory))
}

pub async fn forget_match<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    target: &MediaRefDto,
) -> Result<(), BridgeError> {
    Ok(state
        .resolver(kind.into())
        .forget(&target.require()?)
        .await?)
}
