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
