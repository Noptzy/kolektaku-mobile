mod detail;
mod episodes;
mod listing;
mod payload;
mod registration;
mod script;
mod servers;
mod source;
mod urls;
mod video;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod page_tests;
#[cfg(test)]
mod payload_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod video_tests;

pub use registration::REGISTRATION;
pub use source::{GOGOANIME_ID, GogoanimeSource};
