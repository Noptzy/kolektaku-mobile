mod catalog;
mod covers;
mod discover;
mod graphql;
mod mapper;
mod matching;
mod people_queries;
mod profile_fetch;
mod profile_queries;
mod queries;
mod sanitize;
mod schema;
mod season;

#[cfg(test)]
mod catalog_cover_tests;
#[cfg(test)]
mod catalog_credit_tests;
#[cfg(test)]
mod catalog_detail_tests;
#[cfg(test)]
mod catalog_discover_tests;
#[cfg(test)]
mod catalog_error_tests;
#[cfg(test)]
mod catalog_facts_tests;
#[cfg(test)]
mod catalog_list_tests;
#[cfg(test)]
mod catalog_match_tests;
#[cfg(test)]
mod catalog_people_tests;
#[cfg(test)]
mod catalog_profile_tests;
#[cfg(test)]
mod catalog_test_support;
#[cfg(test)]
mod catalog_titles_tests;

pub use catalog::AniListCatalog;
