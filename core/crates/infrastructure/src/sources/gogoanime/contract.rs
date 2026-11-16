use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "oshi no ko",
        item_id: "oshi-no-ko-season-2",
        min_units: 2,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("/anime/?") {
        Some(fixtures::gogoanime("latest.html"))
    } else if url.contains("?s=") {
        Some(fixtures::gogoanime("search.html"))
    } else if url.contains("/anime/oshi-no-ko-season-2/") {
        Some(fixtures::gogoanime("detail.html"))
    } else {
        None
    }
}
