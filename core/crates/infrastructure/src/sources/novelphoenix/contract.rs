use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "the beginning after the end",
        item_id: "the-beginning-after-the-end",
        min_units: 30,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("/search?keyword=") || url.contains("/genre-all/") {
        Some(fixtures::novelphoenix("search.html"))
    } else if url.contains("/chapters") {
        Some(fixtures::novelphoenix("chapters.html"))
    } else if url.ends_with("/novel/the-beginning-after-the-end") {
        Some(fixtures::novelphoenix("detail.html"))
    } else {
        None
    }
}
