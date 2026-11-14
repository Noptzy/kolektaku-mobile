mod check;
mod decision;
mod download;
mod error;
mod manifest;
mod reqwest_transport;
mod transport;

#[cfg(test)]
mod testing;

#[cfg(test)]
mod check_tests;
#[cfg(test)]
mod decision_tests;
#[cfg(test)]
mod download_resume_tests;
#[cfg(test)]
mod download_tests;
#[cfg(test)]
mod manifest_tests;

pub use check::{RELEASE_REPO, check, manifest_url};
pub use decision::{Decision, Update, decide};
pub use download::{Progress, download};
pub use error::UpdateError;
pub use manifest::{ALLOWED_HOSTS, Asset, Manifest, host_allowed, parse_manifest};
pub use reqwest_transport::ReqwestTransport;
pub use transport::{Body, BoxFuture, Fetched, Transport};
