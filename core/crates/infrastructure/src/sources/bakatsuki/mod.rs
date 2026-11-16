mod catalog;
mod chapter_text;
mod detail;
mod pictures;
mod registration;
mod source;
mod urls;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod urls_tests;

pub use registration::REGISTRATION;
pub use source::{BAKATSUKI_ID, BakaTsukiSource};
