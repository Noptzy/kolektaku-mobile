mod api;
mod episodes;
mod items;
mod model;
mod payload;
mod query;
mod registration;
mod script;
mod servers;
mod source;
mod urls;
mod video;

#[cfg(test)]
mod contract;
#[cfg(test)]
mod items_tests;
#[cfg(test)]
mod payload_tests;
#[cfg(test)]
mod source_tests;
#[cfg(test)]
mod units_tests;
#[cfg(test)]
mod video_tests;

pub use registration::REGISTRATION;
pub use source::{HIANIME_ID, HianimeSource};
