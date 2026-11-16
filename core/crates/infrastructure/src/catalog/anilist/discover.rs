use domain::media::{Discover, DiscoverSort, MediaKind, YearSpan};
use serde_json::{Value, json};

use super::catalog::media_type;
use super::covers::anilist_name;
use super::format_scope::apply_format_scope;

const GENRES: [&str; 19] = [
    "Action",
    "Adventure",
    "Comedy",
    "Drama",
    "Ecchi",
    "Fantasy",
    "Hentai",
    "Horror",
    "Mahou Shoujo",
    "Mecha",
    "Music",
    "Mystery",
    "Psychological",
    "Romance",
    "Sci-Fi",
    "Slice of Life",
    "Sports",
    "Supernatural",
    "Thriller",
];

#[derive(Debug, PartialEq, Eq)]
pub enum GenreArgument {
    Genre(String),
    Tag(String),
}

pub fn genre_argument(site_name: &str) -> GenreArgument {
    let name = anilist_name(site_name);
    if GENRES.contains(&name) {
        GenreArgument::Genre(name.to_string())
    } else {
        GenreArgument::Tag(name.to_string())
    }
}

pub fn start_after(year: u16) -> u32 {
    (u32::from(year) - 1) * 10_000 + 1231
}

pub fn start_before(year: u16) -> u32 {
    (u32::from(year) + 1) * 10_000 + 101
}

fn sort_of(filter: &Discover, searching: bool) -> &'static str {
    match filter.sort {
        DiscoverSort::Relevance if searching => "SEARCH_MATCH",
        DiscoverSort::Relevance => "POPULARITY_DESC",
        DiscoverSort::Newest => "START_DATE_DESC",
        DiscoverSort::Oldest => "START_DATE",
        DiscoverSort::TitleAz => "TITLE_ROMAJI",
        DiscoverSort::TitleZa => "TITLE_ROMAJI_DESC",
    }
}

fn add_years(variables: &mut Value, years: &YearSpan) {
    if let Some(from) = years.from {
        variables["from"] = json!(start_after(from));
    }
    if let Some(to) = years.to {
        variables["to"] = json!(start_before(to));
    }
}

pub fn discover_variables(
    kind: MediaKind,
    filter: &Discover,
    page: u32,
    per_page: u32,
    country: Option<&str>,
) -> Value {
    let query = filter
        .query
        .as_deref()
        .map(str::trim)
        .filter(|text| !text.is_empty());
    let mut variables = json!({
        "page": page,
        "perPage": per_page,
        "type": media_type(kind),
        "sort": [sort_of(filter, query.is_some())],
    });
    if let Some(text) = query {
        variables["search"] = json!(text);
    }
    match filter.genre.as_deref().map(genre_argument) {
        Some(GenreArgument::Genre(name)) => variables["genre"] = json!(name),
        Some(GenreArgument::Tag(name)) => variables["tag"] = json!(name),
        None => {}
    }
    if let Some(years) = &filter.years {
        add_years(&mut variables, years);
    }
    add_facets(&mut variables, filter);
    apply_format_scope(&mut variables, kind);
    if let Some(code) = country {
        variables["country"] = json!(code);
    }
    variables
}

fn add_facets(variables: &mut Value, filter: &Discover) {
    if !filter.formats.is_empty() {
        variables["formats"] = json!(filter.formats);
    }
    if let Some(status) = filter.status {
        variables["status"] = json!(status);
    }
    if let Some(origin) = filter.origin {
        variables["source"] = json!(origin);
    }
}

#[cfg(test)]
mod tests;
