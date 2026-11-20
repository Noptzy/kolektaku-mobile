use crate::dto::downloads::{DownloadDto, DownloadSettingsDto, DownloadTargetDto};
use crate::dto::stream::StreamSetDto;
use crate::error::BridgeError;
use crate::service::downloads;
use crate::state::global;

pub async fn downloads_list() -> Result<Vec<DownloadDto>, BridgeError> {
    Ok(downloads::list(global()?))
}

pub async fn downloads_enqueue(
    target: DownloadTargetDto,
    stream: StreamSetDto,
) -> Result<DownloadDto, BridgeError> {
    downloads::enqueue(global()?, target, stream).await
}

pub async fn downloads_retry(
    id: i64,
    stream: StreamSetDto,
) -> Result<Option<DownloadDto>, BridgeError> {
    downloads::retry(global()?, id, stream).await
}

pub async fn downloads_cancel(id: i64) -> Result<(), BridgeError> {
    downloads::cancel(global()?, id).await
}

pub async fn downloads_remove(id: i64, delete_file: bool) -> Result<(), BridgeError> {
    downloads::remove(global()?, id, delete_file).await
}

pub async fn downloads_relocate(id: i64, path: String) -> Result<(), BridgeError> {
    downloads::relocate(global()?, id, path).await
}

pub async fn downloads_settings() -> Result<DownloadSettingsDto, BridgeError> {
    Ok(downloads::settings(global()?))
}

pub async fn downloads_save_settings(
    settings: DownloadSettingsDto,
) -> Result<DownloadSettingsDto, BridgeError> {
    downloads::save_settings(global()?, settings).await
}

pub async fn downloads_use_folder(folder: String) -> Result<(), BridgeError> {
    downloads::use_folder(global()?, folder);
    Ok(())
}
