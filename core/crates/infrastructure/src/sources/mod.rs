pub mod registry;
pub(crate) mod support;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod contract_failure_tests;
#[cfg(test)]
mod contract_tests;
#[cfg(test)]
mod registry_tests;

pub use registry::{gogoanime, hianime, komikindo, komiku, kuramanime};
pub use support::share_page_cache;
