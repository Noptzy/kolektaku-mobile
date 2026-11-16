use crate::fixtures;
use crate::sources::contract::ContractSite;

pub fn site() -> ContractSite {
    ContractSite {
        route,
        search_query: "hyouka",
        item_id: "Hyouka",
        min_units: 30,
    }
}

fn route(url: &str) -> Option<String> {
    if url.contains("list=categorymembers") {
        Some(fixtures::read("bakatsuki", "category.json"))
    } else if url.ends_with("title=Hyouka") {
        Some(fixtures::read("bakatsuki", "detail.html"))
    } else if url.ends_with("title=Hyouka%3AVolume+1+Chapter+1") {
        Some(fixtures::read("bakatsuki", "chapter.html"))
    } else {
        None
    }
}
