use crate::dto::media::{MediaKindDto, MediaRefDto};
use crate::dto::sources::{DetailViewDto, SourceLinkDto, UnitsDto};
use crate::error::BridgeError;
use crate::service::detail;
use crate::state::global;

pub async fn media_detail(
    kind: MediaKindDto,
    reference: MediaRefDto,
) -> Result<DetailViewDto, BridgeError> {
    detail::media_detail(global()?, kind, &reference).await
}

pub async fn units(
    reference: MediaRefDto,
    source: Option<String>,
) -> Result<UnitsDto, BridgeError> {
    detail::units(global()?, &reference, source).await
}

pub async fn select_source(
    kind: MediaKindDto,
    reference: MediaRefDto,
    source: String,
    item: String,
) -> Result<Vec<SourceLinkDto>, BridgeError> {
    detail::select_source(global()?, kind, &reference, &source, &item).await
}

pub async fn forget_match(kind: MediaKindDto, reference: MediaRefDto) -> Result<(), BridgeError> {
    detail::forget_match(global()?, kind, &reference).await
}
