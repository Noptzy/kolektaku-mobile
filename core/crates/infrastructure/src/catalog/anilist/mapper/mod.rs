mod credits;
mod detail;
mod episodes;
#[cfg(test)]
mod episodes_realign_tests;
#[cfg(test)]
mod episodes_tests;
mod links;
mod people;
mod profile;
mod profile_facts;
mod profile_links;
mod related;
mod summary;

pub use detail::map_detail;
pub use people::{map_people, map_studio};
pub use profile::map_profile;
pub use summary::visible_summaries;
