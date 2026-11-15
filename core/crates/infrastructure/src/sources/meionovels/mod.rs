mod chapter_text;
mod chapters;
mod detail;
mod listing;
mod registration;
mod source;
mod title;
mod urls;

#[cfg(test)]
mod chapter_tests;
#[cfg(test)]
mod contract;
#[cfg(test)]
mod detail_tests;
#[cfg(test)]
mod listing_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod title_tests;
#[cfg(test)]
mod urls_tests;

pub use registration::REGISTRATION;
pub use source::{MEIONOVELS_ID, MeionovelsSource};
