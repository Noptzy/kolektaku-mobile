use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "steel ball run",
        item_id: "steel-ball-run-jojo's-bizarre-adventure-2nd-3rd-stage-13m7yk",
        min_units: 8,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("/api/filter") {
        Some(fixtures::hianime("filter.json"))
    } else if url.contains("/api/latest/anime") {
        Some(fixtures::hianime("latest.json"))
    } else if url.contains("/api/episodes/") {
        Some(fixtures::hianime("episodes.json"))
    } else if url.contains("/api/episode/") {
        Some(fixtures::hianime("episode.json"))
    } else if url.contains("/api/anime/") {
        Some(fixtures::hianime("anime.json"))
    } else {
        None
    }
}
