use std::path::{Path, PathBuf};

use updater::{Decision, Progress, Transport, check, download};

use crate::dto::update::{
    UpdateOfferDto, UpdateProgressDto, asset_of, finished_dto, offer_dto, progress_dto,
};
use crate::error::{BridgeError, BridgeErrorKind};

pub async fn check_for_update(
    transport: &dyn Transport,
    manifest_address: &str,
    installed: &str,
    abis: &[String],
) -> Result<Option<UpdateOfferDto>, BridgeError> {
    let decision = check(transport, manifest_address, installed, abis).await?;
    Ok(match decision {
        Decision::UpToDate => None,
        Decision::Available(update) => Some(offer_dto(&update, false)),
        Decision::Required(update) => Some(offer_dto(&update, true)),
    })
}

pub fn apk_name(offer: &UpdateOfferDto) -> String {
    let clean = |text: &str| -> String {
        text.chars()
            .filter(|c| c.is_ascii_alphanumeric() || *c == '.' || *c == '-')
            .collect()
    };
    format!(
        "kolektaku-{}-{}.apk",
        clean(&offer.version),
        clean(&offer.abi)
    )
}

fn forget_other_downloads(folder: &Path, keep: &str) {
    let Ok(entries) = std::fs::read_dir(folder) else {
        return;
    };
    for entry in entries.flatten() {
        let name = entry.file_name().to_string_lossy().into_owned();
        let is_download = name.starts_with("kolektaku-") && name.contains(".apk");
        let is_kept = name == keep || name == format!("{keep}.part");
        if is_download && !is_kept {
            let _ = std::fs::remove_file(entry.path());
        }
    }
}

fn whole_percent(progress: Progress) -> u64 {
    progress
        .received
        .saturating_mul(100)
        .checked_div(progress.total)
        .unwrap_or(0)
}

pub async fn download_update(
    transport: &dyn Transport,
    offer: &UpdateOfferDto,
    folder: &Path,
    mut emit: impl FnMut(UpdateProgressDto) + Send,
) -> Result<String, BridgeError> {
    if offer.size == 0 {
        return Err(BridgeError::new(
            BridgeErrorKind::Unavailable,
            "the update has no size",
        ));
    }
    let name = apk_name(offer);
    forget_other_downloads(folder, &name);
    let destination: PathBuf = folder.join(&name);
    let mut last_percent = None;
    let path = download(transport, &asset_of(offer), &destination, |progress| {
        let percent = whole_percent(progress);
        if last_percent != Some(percent) {
            last_percent = Some(percent);
            emit(progress_dto(progress));
        }
    })
    .await?;
    let path = path.to_string_lossy().into_owned();
    emit(finished_dto(offer.size, path.clone()));
    Ok(path)
}
