use crate::dto::settings::SettingsDto;
use crate::error::BridgeError;
use crate::service::settings;
use crate::state::global;

pub async fn get_settings() -> Result<SettingsDto, BridgeError> {
    Ok(settings::current(global()?))
}

pub async fn save_settings(settings: SettingsDto) -> Result<SettingsDto, BridgeError> {
    settings::save(global()?, settings).await
}
