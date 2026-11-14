mod chapter;
mod detail;
mod genres;
mod listing;
mod registration;
mod source;
mod urls;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod detail_tests;
#[cfg(test)]
mod listing_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod urls_tests;

pub use source::{KOMIKINDO_ID, KomikindoSource};
pub use registration::REGISTRATION;
