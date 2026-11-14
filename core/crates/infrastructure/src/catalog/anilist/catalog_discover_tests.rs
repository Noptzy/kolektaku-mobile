use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{Discover, DiscoverSort, MediaKind, YearSpan};

use super::catalog_test_support::{
    catalog_failing_with, catalog_with_fixture, sent_query, sent_variables,
};
use crate::http::HttpResponse;

#[tokio::test]
async fn a_genre_and_a_year_are_sent_to_the_catalog_and_the_page_comes_back() {
    let (catalog, http) = catalog_with_fixture("trending-anime.json");
    let filter = Discover::in_genre("Action").within(YearSpan::only(2015));
    let page = catalog
        .discover(MediaKind::Anime, &filter, 2)
        .await
        .unwrap();
    assert!(!page.items.is_empty());
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["genre"], "Action");
    assert_eq!(variables["from"], 20_141_231);
    assert_eq!(variables["to"], 20_160_101);
    assert_eq!(variables["page"], 2);
    assert_eq!(variables["perPage"], 20);
    assert_eq!(variables["country"], "JP");
    assert!(sent_query(&http, 0).contains("startDate_greater: $from"));
}

#[tokio::test]
async fn a_search_with_a_year_keeps_the_text_and_ranks_by_match() {
    let (catalog, http) = catalog_with_fixture("trending-anime.json");
    let filter = Discover::searching("naruto").within(YearSpan::up_to(2010));
    catalog
        .discover(MediaKind::Anime, &filter, 1)
        .await
        .unwrap();
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["search"], "naruto");
    assert_eq!(variables["sort"][0], "SEARCH_MATCH");
    assert!(variables.get("from").is_none());
    assert_eq!(variables["to"], 20_110_101);
}

#[tokio::test]
async fn manga_has_no_country_and_follows_the_asked_order() {
    let (catalog, http) = catalog_with_fixture("search-manga.json");
    let filter = Discover::in_genre("Drama").sorted(DiscoverSort::Oldest);
    catalog
        .discover(MediaKind::Manga, &filter, 1)
        .await
        .unwrap();
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["type"], "MANGA");
    assert!(variables.get("country").is_none());
    assert_eq!(variables["sort"][0], "START_DATE");
}

#[tokio::test]
async fn adult_titles_never_come_back() {
    let (catalog, _) = catalog_with_fixture("trending-anime.json");
    let page = catalog
        .discover(MediaKind::Anime, &Discover::default(), 1)
        .await
        .unwrap();
    assert!(page.items.iter().all(|item| !item.is_adult));
}

#[tokio::test]
async fn a_failing_catalog_is_reported() {
    let catalog = catalog_failing_with(HttpResponse::new(502, "<html>bad gateway</html>"));
    let error = catalog
        .discover(MediaKind::Anime, &Discover::default(), 1)
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}
