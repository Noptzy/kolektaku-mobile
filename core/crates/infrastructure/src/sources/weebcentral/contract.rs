use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "medalist",
        item_id: "01J76XYEB4BNMXCR7TP6YY0VN0/Medalist",
        min_units: 30,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("/search/data") {
        Some(fixtures::weebcentral("search.html"))
    } else if url.ends_with("/full-chapter-list") {
        Some(fixtures::weebcentral("chapters.html"))
    } else if url.contains("/series/01J76XYEB4BNMXCR7TP6YY0VN0/Medalist") {
        Some(fixtures::weebcentral("detail.html"))
    } else {
        None
    }
}
