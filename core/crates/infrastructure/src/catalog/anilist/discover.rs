use domain::media::{Discover, DiscoverSort, MediaKind, YearSpan};
use serde_json::{Value, json};

use super::covers::anilist_name;

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
        "type": match kind {
            MediaKind::Anime => "ANIME",
            MediaKind::Manga => "MANGA",
        },
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
mod tests {
    use domain::media::{MediaFormat, MediaOrigin, MediaStatus};

    use super::*;

    fn vars(filter: &Discover) -> Value {
        discover_variables(MediaKind::Anime, filter, 2, 20, Some("JP"))
    }

    #[test]
    fn a_catalog_genre_is_asked_as_a_genre_and_the_rest_as_tags() {
        assert_eq!(
            genre_argument("Action"),
            GenreArgument::Genre("Action".into())
        );
        assert_eq!(
            genre_argument("Suspense"),
            GenreArgument::Genre("Thriller".into())
        );
        assert_eq!(
            genre_argument("CGDCT"),
            GenreArgument::Tag("Cute Girls Doing Cute Things".into())
        );
        assert_eq!(
            genre_argument("Samurai"),
            GenreArgument::Tag("Samurai".into())
        );
    }

    #[test]
    fn a_year_becomes_a_window_the_dates_must_fall_inside() {
        assert_eq!(start_after(2015), 20_141_231);
        assert_eq!(start_before(2015), 20_160_101);
    }

    #[test]
    fn one_year_sets_both_ends() {
        let variables = vars(&Discover::in_genre("Action").within(YearSpan::only(2015)));
        assert_eq!(variables["from"], 20_141_231);
        assert_eq!(variables["to"], 20_160_101);
        assert_eq!(variables["genre"], "Action");
        assert!(variables.get("tag").is_none());
    }

    #[test]
    fn an_up_to_year_leaves_the_start_open() {
        let variables = vars(&Discover::in_genre("Drama").within(YearSpan::up_to(2014)));
        assert!(variables.get("from").is_none());
        assert_eq!(variables["to"], 20_150_101);
    }

    #[test]
    fn a_tag_genre_uses_the_tag_argument() {
        let variables = vars(&Discover::in_genre("CGDCT"));
        assert_eq!(variables["tag"], "Cute Girls Doing Cute Things");
        assert!(variables.get("genre").is_none());
    }

    #[test]
    fn searching_ranks_by_match_and_browsing_by_popularity() {
        assert_eq!(
            vars(&Discover::searching("naruto"))["sort"][0],
            "SEARCH_MATCH"
        );
        assert_eq!(
            vars(&Discover::in_genre("Action"))["sort"][0],
            "POPULARITY_DESC"
        );
    }

    #[test]
    fn an_explicit_order_wins_over_the_default() {
        let newest = Discover::in_genre("Action").sorted(DiscoverSort::Newest);
        assert_eq!(vars(&newest)["sort"][0], "START_DATE_DESC");
        let za = Discover::in_genre("Action").sorted(DiscoverSort::TitleZa);
        assert_eq!(vars(&za)["sort"][0], "TITLE_ROMAJI_DESC");
    }

    #[test]
    fn a_blank_query_is_not_sent() {
        assert!(vars(&Discover::searching("   ")).get("search").is_none());
        assert_eq!(vars(&Discover::searching(" naruto "))["search"], "naruto");
    }

    #[test]
    fn formats_status_and_origin_use_the_catalog_names() {
        let filter = Discover::searching("a")
            .in_formats(vec![MediaFormat::Tv, MediaFormat::TvShort])
            .with_status(MediaStatus::NotYetReleased)
            .adapted_from(MediaOrigin::LightNovel);
        let variables = vars(&filter);
        assert_eq!(variables["formats"], json!(["TV", "TV_SHORT"]));
        assert_eq!(variables["status"], "NOT_YET_RELEASED");
        assert_eq!(variables["source"], "LIGHT_NOVEL");
    }

    #[test]
    fn without_those_filters_nothing_extra_is_sent() {
        let variables = vars(&Discover::searching("a"));
        for key in ["formats", "status", "source"] {
            assert!(variables.get(key).is_none(), "{key}");
        }
    }

    #[test]
    fn the_country_only_applies_when_given() {
        let manga = discover_variables(MediaKind::Manga, &Discover::default(), 1, 20, None);
        assert!(manga.get("country").is_none());
        assert_eq!(manga["type"], "MANGA");
        assert_eq!(vars(&Discover::default())["country"], "JP");
    }
}
