use crate::dto::cards::{CardPageDto, HomeDto};
use crate::dto::covers::GenreCoverDto;
use crate::dto::discover::DiscoverFilterDto;
use crate::dto::media::MediaKindDto;
use crate::dto::sources::{GenreDto, SourceItemDto};
use crate::error::BridgeError;
use crate::service::browse::{self, SourceOrderDto};
use crate::state::global;

pub async fn home(kind: MediaKindDto) -> Result<HomeDto, BridgeError> {
    browse::home(global()?, kind).await
}

pub async fn search(
    kind: MediaKindDto,
    query: String,
    page: u32,
) -> Result<CardPageDto, BridgeError> {
    browse::search(global()?, kind, &query, page).await
}

pub async fn genres(kind: MediaKindDto) -> Result<Vec<GenreDto>, BridgeError> {
    browse::genres(global()?, kind).await
}

pub async fn discover(
    kind: MediaKindDto,
    filter: DiscoverFilterDto,
    page: u32,
) -> Result<CardPageDto, BridgeError> {
    browse::discover(global()?, kind, filter, page).await
}

pub async fn genre_covers(
    kind: MediaKindDto,
    genres: Vec<String>,
) -> Result<Vec<GenreCoverDto>, BridgeError> {
    browse::genre_covers(global()?, kind, &genres).await
}

pub async fn by_genre(
    kind: MediaKindDto,
    slug: String,
    page: u32,
    order: SourceOrderDto,
) -> Result<CardPageDto, BridgeError> {
    browse::by_genre(global()?, kind, &slug, page, order).await
}

pub async fn source_candidates(
    source: String,
    query: String,
) -> Result<Vec<SourceItemDto>, BridgeError> {
    browse::source_candidates(global()?, &source, &query).await
}
