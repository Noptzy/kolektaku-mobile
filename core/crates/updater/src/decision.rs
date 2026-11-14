use semver::Version;

use crate::error::UpdateError;
use crate::manifest::{Asset, Manifest};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Update {
    pub version: Version,
    pub notes: String,
    pub abi: String,
    pub asset: Asset,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Decision {
    UpToDate,
    Available(Update),
    Required(Update),
}

pub fn decide(
    installed: &Version,
    manifest: &Manifest,
    abis: &[String],
) -> Result<Decision, UpdateError> {
    if installed >= &manifest.version {
        return Ok(Decision::UpToDate);
    }
    let (abi, asset) = abis
        .iter()
        .find_map(|abi| manifest.assets.get(abi).map(|asset| (abi, asset)))
        .ok_or(UpdateError::NoAsset)?;
    let update = Update {
        version: manifest.version.clone(),
        notes: manifest.notes.clone(),
        abi: abi.clone(),
        asset: asset.clone(),
    };
    if installed < &manifest.min_supported {
        Ok(Decision::Required(update))
    } else {
        Ok(Decision::Available(update))
    }
}
