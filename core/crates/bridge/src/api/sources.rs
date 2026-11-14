use crate::dto::sources::SourceStatusDto;
use crate::error::BridgeError;
use crate::service::sources;
use crate::state::global;

pub async fn sources_status() -> Result<Vec<SourceStatusDto>, BridgeError> {
    Ok(sources::status(global()?))
}

pub async fn set_source_enabled(id: String, enabled: bool) -> Result<(), BridgeError> {
    sources::set_enabled(global()?, &id, enabled).await;
    Ok(())
}
