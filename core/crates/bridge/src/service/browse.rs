use application::catalog::{DiscoverMedia, GenreBrowse, GenreCovers, HomeFeed, SearchMedia};
use application::ports::MetadataCatalog;
use domain::source::{SourceId, SourceOrder, SourceSearch};

use crate::dto::cards::{CardPageDto, HomeDto};
use crate::dto::covers::GenreCoverDto;
use crate::dto::discover::DiscoverFilterDto;
use crate::dto::media::MediaKindDto;
use crate::dto::sources::{GenreDto, SourceItemDto, item_dto};
use crate::error::BridgeError;
use crate::state::AppState;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SourceOrderDto {
    Newest,
    Oldest,
    Az,
    Za,
}

impl From<SourceOrderDto> for SourceOrder {
    fn from(order: SourceOrderDto) -> Self {
        match order {
            SourceOrderDto::Newest => Self::Newest,
            SourceOrderDto::Oldest => Self::Oldest,
            SourceOrderDto::Az => Self::Az,
            SourceOrderDto::Za => Self::Za,
        }
    }
}

pub async fn home<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<HomeDto, BridgeError> {
    let kind = kind.into();
    let feed = HomeFeed::new(
        state.catalog.clone(),
        state.active_sources(kind),
        state.clock.clone(),
    );
    Ok(HomeDto::from(&feed.execute(kind).await?))
}

pub async fn clear_catalog_cache<C: MetadataCatalog + 'static>(state: &AppState<C>) {
    if let Some(cache) = &state.response_cache {
        cache.clear().await;
    }
}

pub async fn search<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    query: &str,
    page: u32,
) -> Result<CardPageDto, BridgeError> {
    let kind = kind.into();
    let search = SearchMedia::new(
        state.catalog.clone(),
        state.active_sources(kind),
        state.clock.clone(),
    );
    Ok(CardPageDto::from(&search.execute(kind, query, page).await?))
}

fn browse<C: MetadataCatalog + 'static>(state: &AppState<C>, kind: MediaKindDto) -> GenreBrowse<C> {
    GenreBrowse::new(
        state.catalog.clone(),
        state.active_sources(kind.into()),
        state.clock.clone(),
    )
}

pub async fn genres<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
) -> Result<Vec<GenreDto>, BridgeError> {
    Ok(browse(state, kind)
        .genres()
        .await?
        .iter()
        .map(Into::into)
        .collect())
}

pub async fn discover<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    filter: DiscoverFilterDto,
    page: u32,
) -> Result<CardPageDto, BridgeError> {
    let found = DiscoverMedia::new(state.catalog.clone(), state.clock.clone())
        .execute(kind.into(), &filter.into(), page)
        .await?;
    Ok(CardPageDto::from(&found))
}

pub async fn genre_covers<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    genres: &[String],
) -> Result<Vec<GenreCoverDto>, BridgeError> {
    let covers = GenreCovers::new(state.catalog.clone())
        .execute(kind.into(), genres)
        .await?;
    Ok(covers.iter().map(Into::into).collect())
}

pub async fn by_genre<C: MetadataCatalog + 'static>(
    state: &AppState<C>,
    kind: MediaKindDto,
    slug: &str,
    page: u32,
    order: SourceOrderDto,
) -> Result<CardPageDto, BridgeError> {
    let result = browse(state, kind)
        .by_genre(kind.into(), slug, page, order.into())
        .await?;
    Ok(CardPageDto::from(&result))
}

pub async fn source_candidates<C: MetadataCatalog>(
    state: &AppState<C>,
    source: &str,
    query: &str,
) -> Result<Vec<SourceItemDto>, BridgeError> {
    let id = SourceId::new(source);
    let page = state
        .directory
        .get(&id)?
        .search(SourceSearch::new(query))
        .await?;
    Ok(page
        .items
        .iter()
        .map(|item| item_dto(source, item))
        .collect())
}
