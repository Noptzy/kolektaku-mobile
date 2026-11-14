mod attempt;
mod directory;
mod find_link;
mod health;
mod merge;
mod next_source;
mod rank;
mod resolve_sources;
mod resolved_sources;
mod switches;

#[cfg(test)]
mod resolve_manual_tests;
#[cfg(test)]
mod resolve_sources_tests;
#[cfg(test)]
mod resolve_support;

pub use attempt::{Working, candidate_links, find_unit, first_working};
pub use directory::SourceDirectory;
pub use health::SourceHealth;
pub use next_source::next_source_for;
pub use rank::rank_links;
pub use resolve_sources::ResolveSources;
pub use resolved_sources::ResolvedSources;
pub use switches::SourceSwitches;
