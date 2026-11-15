mod chapter_text;
mod chapters;
mod detail;
mod listing;
mod registration;
mod source;
mod urls;

#[cfg(test)]
mod chapter_tests;
#[cfg(test)]
mod contract;
#[cfg(test)]
mod listing_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod urls_tests;

pub use registration::REGISTRATION;
pub use source::{NOVELPHOENIX_ID, NovelPhoenixSource};
