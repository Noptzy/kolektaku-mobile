use std::collections::BTreeMap;

use semver::Version;
use serde::Deserialize;
use url::Url;

use crate::error::UpdateError;

pub const ALLOWED_HOSTS: [&str; 3] = [
    "github.com",
    "objects.githubusercontent.com",
    "release-assets.githubusercontent.com",
];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Asset {
    pub url: String,
    pub size: u64,
    pub sha256: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Manifest {
    pub version: Version,
    pub min_supported: Version,
    pub notes: String,
    pub assets: BTreeMap<String, Asset>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct RawManifest {
    version: String,
    min_supported: Option<String>,
    notes: Option<String>,
    assets: Option<BTreeMap<String, RawAsset>>,
}

#[derive(Deserialize)]
struct RawAsset {
    url: Option<String>,
    size: Option<u64>,
    sha256: Option<String>,
}

pub fn host_allowed(address: &str) -> bool {
    let Ok(parsed) = Url::parse(address) else {
        return false;
    };
    parsed.scheme() == "https"
        && parsed
            .host_str()
            .is_some_and(|host| ALLOWED_HOSTS.contains(&host))
}

fn valid_hash(text: &str) -> bool {
    text.len() == 64 && text.chars().all(|letter| letter.is_ascii_hexdigit())
}

fn read_asset(raw: RawAsset) -> Option<Asset> {
    let url = raw.url.filter(|address| host_allowed(address))?;
    let size = raw.size.filter(|size| *size > 0)?;
    let sha256 = raw.sha256.filter(|hash| valid_hash(hash))?;
    Some(Asset {
        url,
        size,
        sha256: sha256.to_lowercase(),
    })
}

fn version_of(text: &str, what: &str) -> Result<Version, UpdateError> {
    Version::parse(text.trim().trim_start_matches('v'))
        .map_err(|error| UpdateError::BadManifest(format!("{what} is not a version: {error}")))
}

pub fn parse_manifest(text: &str) -> Result<Manifest, UpdateError> {
    let raw: RawManifest =
        serde_json::from_str(text).map_err(|error| UpdateError::BadManifest(error.to_string()))?;
    let version = version_of(&raw.version, "version")?;
    let min_supported = match raw.min_supported {
        Some(text) => version_of(&text, "minSupported")?,
        None => Version::new(0, 0, 0),
    };
    let assets = raw
        .assets
        .unwrap_or_default()
        .into_iter()
        .filter_map(|(abi, asset)| Some((abi, read_asset(asset)?)))
        .collect();
    Ok(Manifest {
        version,
        min_supported,
        notes: raw.notes.unwrap_or_default().trim().to_string(),
        assets,
    })
}
