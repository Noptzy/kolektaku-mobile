use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "chainsaw man",
        item_id: "123213-chainsaw-man",
        min_units: 39,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("post_type=manga") {
        Some(fixtures::komiku("listing-search.html"))
    } else if url.starts_with("https://api.komiku.org") {
        Some(fixtures::komiku("listing-genre.html"))
    } else if url.contains("/manga/123213-chainsaw-man/") {
        Some(fixtures::komiku("detail.html"))
    } else {
        None
    }
}
