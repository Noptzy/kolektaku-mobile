use crate::dto::library::{FavoriteDto, ProgressDto, UnitOrderDto};
use crate::dto::media::{MediaKindDto, MediaRefDto};
use crate::error::BridgeError;
use crate::service::library;
use crate::state::global;

pub async fn library_favorites(kind: MediaKindDto) -> Result<Vec<FavoriteDto>, BridgeError> {
    library::favorites(global()?, kind).await
}

pub async fn library_is_favorite(
    kind: MediaKindDto,
    reference: MediaRefDto,
) -> Result<bool, BridgeError> {
    library::is_favorite(global()?, kind, &reference).await
}

pub async fn library_toggle_favorite(favorite: FavoriteDto) -> Result<bool, BridgeError> {
    library::toggle_favorite(global()?, favorite).await
}

pub async fn library_history(kind: MediaKindDto) -> Result<Vec<ProgressDto>, BridgeError> {
    library::history(global()?, kind).await
}

pub async fn library_continue(kind: MediaKindDto) -> Result<Vec<ProgressDto>, BridgeError> {
    library::continue_list(global()?, kind).await
}

pub async fn library_save_progress(progress: ProgressDto) -> Result<(), BridgeError> {
    library::save_progress(global()?, progress).await
}

pub async fn library_progress_for(
    kind: MediaKindDto,
    reference: MediaRefDto,
    unit_number: f64,
) -> Result<Option<ProgressDto>, BridgeError> {
    library::progress_for(global()?, kind, &reference, unit_number).await
}

pub async fn library_last_progress(
    kind: MediaKindDto,
    reference: MediaRefDto,
) -> Result<Option<ProgressDto>, BridgeError> {
    library::last_progress(global()?, kind, &reference).await
}

pub async fn library_remove_progress(
    kind: MediaKindDto,
    reference: MediaRefDto,
    unit_number: f64,
) -> Result<(), BridgeError> {
    library::remove_progress(global()?, kind, &reference, unit_number).await
}

pub async fn library_clear_history(kind: MediaKindDto) -> Result<(), BridgeError> {
    library::clear_history(global()?, kind).await
}

pub async fn library_unit_order(
    kind: MediaKindDto,
    reference: MediaRefDto,
) -> Result<UnitOrderDto, BridgeError> {
    library::unit_order(global()?, kind, &reference).await
}

pub async fn library_set_unit_order(
    kind: MediaKindDto,
    reference: MediaRefDto,
    order: UnitOrderDto,
) -> Result<(), BridgeError> {
    library::set_unit_order(global()?, kind, &reference, order).await
}

pub async fn library_searches(kind: MediaKindDto) -> Result<Vec<String>, BridgeError> {
    library::searches(global()?, kind).await
}

pub async fn library_add_search(kind: MediaKindDto, query: String) -> Result<(), BridgeError> {
    library::add_search(global()?, kind, &query).await
}

pub async fn library_clear_searches(kind: MediaKindDto) -> Result<(), BridgeError> {
    library::clear_searches(global()?, kind).await
}

pub async fn library_preference(name: String) -> Result<Option<String>, BridgeError> {
    library::preference(global()?, &name).await
}

pub async fn library_set_preference(name: String, value: String) -> Result<(), BridgeError> {
    library::set_preference(global()?, &name, &value).await
}
