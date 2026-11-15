use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "mushoku tensei",
        item_id: "mushoku-tensei-ln",
        min_units: 50,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("post_type=wp-manga") {
        Some(fixtures::meionovels("search.html"))
    } else if url.contains("m_orderby=latest") {
        Some(fixtures::meionovels("latest.html"))
    } else if url.ends_with("/ajax/chapters/") {
        Some(fixtures::meionovels("ajax-chapters.html"))
    } else if url.ends_with("/novel/mushoku-tensei-ln/") {
        Some(fixtures::meionovels("detail.html"))
    } else {
        None
    }
}
