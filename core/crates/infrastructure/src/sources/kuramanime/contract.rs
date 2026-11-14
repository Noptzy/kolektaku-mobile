use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "one piece",
        item_id: "50/one-piece",
        min_units: 2,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("/quick/ongoing") {
        Some(fixtures::kuramanime("latest-page-current.html"))
    } else if url.contains("search=") {
        Some(fixtures::kuramanime("listing-small.html"))
    } else if url.contains("/anime/50/one-piece") {
        Some(fixtures::kuramanime("detail-small.html"))
    } else {
        None
    }
}
