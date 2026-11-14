use std::sync::Arc;

use application::ports::MetadataCatalog;
use domain::error::SourceError;
use domain::media::{MediaKind, MediaListKind};
use serde_json::{Value, json};

use super::catalog_test_support::{
    OCTOBER_2026, catalog_over, catalog_replying, catalog_with_fixture, sent_query, sent_variables,
};
use crate::fixtures;
use crate::http::{FakeHttp, HttpResponse};

#[tokio::test]
async fn lists_trending_anime_restricted_to_japanese_titles() {
    let (catalog, http) = catalog_with_fixture("trending-anime.json");
    let page = catalog
        .list(MediaKind::Anime, MediaListKind::Trending, 1)
        .await
        .unwrap();
    assert!(!page.items.is_empty());
    assert!(page.items.iter().all(|item| item.kind == MediaKind::Anime));
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["type"], "ANIME");
    assert_eq!(variables["country"], "JP");
    assert_eq!(
        variables["sort"],
        json!(["TRENDING_DESC", "POPULARITY_DESC"])
    );
    assert_eq!(variables["perPage"], 20);
}

#[tokio::test]
async fn asks_for_the_current_season_and_year_on_the_seasonal_list() {
    let (catalog, http) = catalog_with_fixture("seasonal-anime.json");
    catalog
        .list(MediaKind::Anime, MediaListKind::Seasonal, 1)
        .await
        .unwrap();
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["season"], "FALL");
    assert_eq!(variables["year"], 2026);
}

#[tokio::test]
async fn popular_manga_has_no_country_filter() {
    let (catalog, http) = catalog_with_fixture("search-manga.json");
    catalog
        .list(MediaKind::Manga, MediaListKind::Popular, 2)
        .await
        .unwrap();
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["page"], 2);
    assert_eq!(variables["sort"], json!(["POPULARITY_DESC"]));
    assert!(variables.get("country").is_none());
}

#[tokio::test]
async fn does_not_offer_a_seasonal_list_for_manga() {
    let (catalog, http) = catalog_replying("{}".into());
    let error = catalog
        .list(MediaKind::Manga, MediaListKind::Seasonal, 1)
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unsupported(_)));
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn searches_manga_without_the_country_filter_and_trims_the_query() {
    let (catalog, http) = catalog_with_fixture("search-manga.json");
    let page = catalog
        .search(MediaKind::Manga, "  Chainsaw Man ", 1)
        .await
        .unwrap();
    assert!(!page.items.is_empty());
    let variables = sent_variables(&http, 0);
    assert_eq!(variables["type"], "MANGA");
    assert_eq!(variables["search"], "Chainsaw Man");
    assert!(variables.get("country").is_none());
}

#[tokio::test]
async fn reports_the_page_info_the_catalog_sends() {
    let body = json!({"data": {"Page": {"pageInfo": {"currentPage": 3, "hasNextPage": true}, "media": []}}});
    let (catalog, _) = catalog_replying(body.to_string());
    let page = catalog.search(MediaKind::Anime, "x", 3).await.unwrap();
    assert_eq!((page.page, page.has_next_page), (3, true));
}

#[tokio::test]
async fn falls_back_to_the_requested_page_without_page_info() {
    let (catalog, _) = catalog_replying(json!({"data": {"Page": {"media": []}}}).to_string());
    let page = catalog.search(MediaKind::Anime, "x", 4).await.unwrap();
    assert_eq!((page.page, page.has_next_page), (4, false));
}

#[tokio::test]
async fn matches_many_titles_in_one_request_using_aliases() {
    let (catalog, http) = catalog_with_fixture("batch-anime.json");
    let titles: Vec<String> = [
        "One Piece",
        "Oshi no Ko 2nd Season",
        "zzzz tidak ada judul ini qqqq",
    ]
    .iter()
    .map(|title| title.to_string())
    .collect();
    let matches = catalog
        .match_titles(MediaKind::Anime, &titles)
        .await
        .unwrap();
    assert_eq!(http.requests().len(), 1);
    assert!(sent_query(&http, 0).contains("m2: Page"));
    assert_eq!(sent_variables(&http, 0)["t1"], "Oshi no Ko 2nd Season");
    assert_eq!(matches.len(), 3);
    assert_eq!(matches[0][0].title.romaji.to_lowercase(), "one piece");
    assert!(!matches[1].is_empty());
}

#[tokio::test]
async fn skips_the_request_entirely_for_an_empty_batch() {
    let (catalog, http) = catalog_replying("{}".into());
    assert!(
        catalog
            .match_titles(MediaKind::Anime, &[])
            .await
            .unwrap()
            .is_empty()
    );
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn a_title_missing_from_the_batch_answer_gets_no_candidates() {
    let body = json!({"data": {"m0": {"media": []}}});
    let (catalog, _) = catalog_replying(body.to_string());
    let titles = vec!["a".to_string(), "b".to_string()];
    let matches = catalog
        .match_titles(MediaKind::Anime, &titles)
        .await
        .unwrap();
    assert_eq!(matches, vec![Vec::new(), Vec::new()]);
}

#[tokio::test]
async fn hides_adult_entries_that_slip_through_a_list() {
    let mut body: Value = serde_json::from_str(&fixtures::anilist("trending-anime.json")).unwrap();
    let total = body["data"]["Page"]["media"].as_array().unwrap().len();
    body["data"]["Page"]["media"][0]["isAdult"] = json!(true);
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, body.to_string())));
    let page = catalog_over(http, OCTOBER_2026)
        .list(MediaKind::Anime, MediaListKind::Trending, 1)
        .await
        .unwrap();
    assert_eq!(page.items.len(), total - 1);
}
