use std::path::Path;

use updater::{ReqwestTransport, due, manifest_url};

use crate::dto::update::{UpdateOfferDto, UpdateProgressDto};
use crate::error::BridgeError;
use crate::frb_generated::StreamSink;
use crate::service::update;

pub async fn check_update(
    installed: String,
    abis: Vec<String>,
) -> Result<Option<UpdateOfferDto>, BridgeError> {
    let transport = ReqwestTransport::new()?;
    update::check_for_update(&transport, &manifest_url(), &installed, &abis).await
}

pub async fn download_update(
    offer: UpdateOfferDto,
    folder: String,
    progress: StreamSink<UpdateProgressDto>,
) -> Result<(), BridgeError> {
    let transport = ReqwestTransport::new()?;
    update::download_update(&transport, &offer, Path::new(&folder), |event| {
        let _ = progress.add(event);
    })
    .await?;
    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_due(last_checked_secs: Option<u64>, now_secs: u64, manual: bool) -> bool {
    due(last_checked_secs, now_secs, manual)
}
