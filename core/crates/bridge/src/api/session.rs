use crate::error::BridgeError;
use crate::state::install;

pub async fn init(app_dir: String, app_version: String) -> Result<String, BridgeError> {
    install(std::path::Path::new(&app_dir)).await?;
    Ok(app_version)
}
