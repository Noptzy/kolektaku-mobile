mod attempt;
mod candidates;
mod directory;
mod find_link;
mod health;
mod merge;
mod misses;
mod next_source;
mod rank;
mod resolve_search;
mod resolve_sources;
mod resolved_sources;
mod search_queries;
mod switches;
mod variants;

#[cfg(test)]
mod catalog_id_tests;
#[cfg(test)]
mod reported_cases_tests;
#[cfg(test)]
mod resolve_manual_tests;
#[cfg(test)]
mod resolve_new_source_tests;
#[cfg(test)]
mod resolve_sources_tests;
#[cfg(test)]
mod resolve_support;
#[cfg(test)]
mod search_fragments_tests;
#[cfg(test)]
mod search_queries_tests;

pub use attempt::{Working, candidate_links, find_unit, first_working};
pub use directory::SourceDirectory;
pub use health::SourceHealth;
pub use next_source::next_source_for;
pub use rank::rank_links;
pub use resolve_sources::ResolveSources;
pub use resolved_sources::ResolvedSources;
pub use search_queries::search_queries;
pub use switches::SourceSwitches;
