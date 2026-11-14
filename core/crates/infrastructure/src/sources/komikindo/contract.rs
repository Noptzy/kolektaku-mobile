use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "chainsaw",
        item_id: "chainsaw-man",
        min_units: 4,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("?s=") {
        Some(fixtures::komikindo("search.html"))
    } else if url.contains("/komik-terbaru") {
        Some(fixtures::komikindo("latest.html"))
    } else if url.contains("/komik/chainsaw-man/") {
        Some(fixtures::komikindo("detail.html"))
    } else {
        None
    }
}
