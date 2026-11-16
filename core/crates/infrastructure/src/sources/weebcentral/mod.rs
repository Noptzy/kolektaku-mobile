mod chapter_pages;
mod chapters;
mod detail;
mod listing;
mod registration;
mod source;
mod urls;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod parse_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod urls_tests;

pub use registration::REGISTRATION;
pub use source::{WEEBCENTRAL_ID, WeebCentralSource};
