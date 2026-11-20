use std::path::PathBuf;

use application::ports::MetadataCatalog;

use crate::dto::downloads::{DownloadDto, DownloadSettingsDto, DownloadTargetDto};
use crate::dto::stream::StreamSetDto;
use crate::dto::stream_input::stream_set_from;
use crate::error::BridgeError;
use crate::state::AppState;

pub fn list<C: MetadataCatalog>(state: &AppState<C>) -> Vec<DownloadDto> {
    state.downloads.snapshot().iter().map(Into::into).collect()
}

pub async fn enqueue<C: MetadataCatalog>(
    state: &AppState<C>,
    target: DownloadTargetDto,
    stream: StreamSetDto,
) -> Result<DownloadDto, BridgeError> {
    let stream = stream_set_from(&stream);
    if stream.sources.is_empty() {
        return Err(BridgeError::not_found("this episode has no video to save"));
    }
    let job = state.downloads.enqueue(target.to_domain()?, stream).await?;
    Ok((&job).into())
}

pub async fn retry<C: MetadataCatalog>(
    state: &AppState<C>,
    id: i64,
    stream: StreamSetDto,
) -> Result<Option<DownloadDto>, BridgeError> {
    let job = state.downloads.retry(id, stream_set_from(&stream)).await?;
    Ok(job.as_ref().map(Into::into))
}

pub async fn cancel<C: MetadataCatalog>(state: &AppState<C>, id: i64) -> Result<(), BridgeError> {
    Ok(state.downloads.cancel(id).await?)
}

pub async fn remove<C: MetadataCatalog>(
    state: &AppState<C>,
    id: i64,
    delete_file: bool,
) -> Result<(), BridgeError> {
    Ok(state.downloads.remove(id, delete_file).await?)
}

pub async fn relocate<C: MetadataCatalog>(
    state: &AppState<C>,
    id: i64,
    path: String,
) -> Result<(), BridgeError> {
    Ok(state.downloads.relocate(id, path).await?)
}

pub fn settings<C: MetadataCatalog>(state: &AppState<C>) -> DownloadSettingsDto {
    state.downloads.settings().get().into()
}

pub async fn save_settings<C: MetadataCatalog>(
    state: &AppState<C>,
    settings: DownloadSettingsDto,
) -> Result<DownloadSettingsDto, BridgeError> {
    let chosen = settings.to_domain();
    state
        .downloads
        .settings()
        .save(state.library.as_ref(), chosen)
        .await?;
    Ok(chosen.into())
}

pub fn use_folder<C: MetadataCatalog>(state: &AppState<C>, folder: String) {
    if !folder.trim().is_empty() {
        state.downloader.set_output(PathBuf::from(folder));
    }
}
