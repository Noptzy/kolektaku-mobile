use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "alpha",
        item_id: "alpha",
        min_units: 2,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("/latest") || url.contains("/search") {
        Some(fixtures::read("example", "list.html"))
    } else if url.contains("/title/alpha") {
        Some(fixtures::read("example", "detail.html"))
    } else {
        None
    }
}
