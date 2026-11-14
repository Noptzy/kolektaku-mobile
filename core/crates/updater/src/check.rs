use semver::Version;

use crate::decision::{Decision, decide};
use crate::error::UpdateError;
use crate::manifest::{host_allowed, parse_manifest};
use crate::transport::Transport;

pub const RELEASE_REPO: &str = "Noptzy/kolektaku-mobile";

pub fn manifest_url() -> String {
    format!("https://github.com/{RELEASE_REPO}/releases/latest/download/latest.json")
}

pub async fn check(
    transport: &dyn Transport,
    manifest_address: &str,
    installed: &str,
    abis: &[String],
) -> Result<Decision, UpdateError> {
    if !host_allowed(manifest_address) {
        return Err(UpdateError::Untrusted(manifest_address.to_string()));
    }
    let installed = Version::parse(installed.trim().trim_start_matches('v'))
        .map_err(|error| UpdateError::BadManifest(format!("installed version: {error}")))?;
    let text = transport.text(manifest_address).await?;
    decide(&installed, &parse_manifest(&text)?, abis)
}
