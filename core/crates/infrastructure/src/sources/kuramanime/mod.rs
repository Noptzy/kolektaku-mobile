mod detail;
mod episodes;
mod genres;
mod ids;
mod listing;
mod registration;
mod payload;
mod quality;
mod script;
mod servers;
mod source;
mod urls;
mod video;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod detail_tests;
#[cfg(test)]
mod listing_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod units_tests;
#[cfg(test)]
mod urls_tests;

pub use source::{KURAMANIME_ID, KuramanimeSource};
pub use registration::REGISTRATION;
