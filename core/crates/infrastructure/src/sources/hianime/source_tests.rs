use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceSearch, StreamSupport};
use serde_json::json;

use super::source::HianimeSource;
use crate::fixtures;
use crate::http::{FakeHttp, HttpMethod, HttpRequest, HttpResponse};

const API: &str = "https://api.example.test/api";
const SLUG: &str = "steel-ball-run-jojo's-bizarre-adventure-2nd-3rd-stage-13m7yk";

pub fn source_over(http: Arc<FakeHttp>) -> HianimeSource {
    HianimeSource::new(http, Arc::new(FakeClock::at(0)), API, 2).unwrap()
}

fn ok(body: impl Into<String>) -> Result<HttpResponse, SourceError> {
    Ok(HttpResponse::new(200, body))
}

fn empty_results() -> String {
    json!({ "total": 0, "page": 1, "limit": 20, "totalPages": 0, "results": [] }).to_string()
}

fn keyword_of(request: &HttpRequest) -> String {
    let body: serde_json::Value = serde_json::from_str(request.body.as_deref().unwrap()).unwrap();
    body["keyword"].as_str().unwrap().to_string()
}

#[test]
fn the_source_describes_itself_for_the_settings_screen() {
    let source = source_over(Arc::new(FakeHttp::always(HttpResponse::new(200, ""))));
    let info = source.info();
    assert_eq!(info.id.as_str(), "hianime");
    assert_eq!(info.kind, MediaKind::Anime);
    assert_eq!(info.priority, 2);
    assert_eq!(info.capabilities.stream, StreamSupport::NeedsWebView);
    assert!(!info.capabilities.genres);
    assert!(info.summary.contains("Inggris"));
    assert!(info.summary.contains("Indonesia"));
}

#[tokio::test]
async fn a_search_posts_the_keyword_and_lists_the_matches() {
    let http = Arc::new(FakeHttp::scripted(vec![ok(fixtures::hianime("filter.json"))]));
    let page = source_over(http.clone())
        .search(SourceSearch::new("steel ball run"))
        .await
        .unwrap();
    assert_eq!(page.items.len(), 2);
    assert_eq!(page.items[0].item_id.as_str(), SLUG);
    assert_eq!((page.page, page.total_pages), (1, 1));
    let sent = http.requests();
    assert_eq!(sent[0].method, HttpMethod::Post);
    assert_eq!(sent[0].url, "https://api.example.test/api/filter");
    assert_eq!(keyword_of(&sent[0]), "steel ball run");
}

#[tokio::test]
async fn a_title_the_site_words_differently_is_found_with_a_shorter_query() {
    let http = Arc::new(FakeHttp::scripted(vec![
        ok(empty_results()),
        ok(empty_results()),
        ok(fixtures::hianime("filter.json")),
    ]));
    let page = source_over(http.clone())
        .search(SourceSearch::new(
            "STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE",
        ))
        .await
        .unwrap();
    assert_eq!(page.items.len(), 2);
    let keywords: Vec<String> = http.requests().iter().map(keyword_of).collect();
    assert_eq!(
        keywords,
        [
            "STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE",
            "STEEL BALL RUN JoJo's Bizarre Adventure 2nd",
            "STEEL BALL RUN",
        ]
    );
}

#[tokio::test]
async fn nothing_found_anywhere_is_an_empty_page_not_an_error() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, empty_results())));
    let page = source_over(http.clone())
        .search(SourceSearch::new("judul yang tidak ada sama sekali"))
        .await
        .unwrap();
    assert!(page.items.is_empty());
    assert!(http.requests().len() <= 4);
}

#[tokio::test]
async fn a_later_page_only_asks_for_the_full_query() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, empty_results())));
    let mut search = SourceSearch::new("one piece movie");
    search.page = 2;
    let page = source_over(http.clone()).search(search).await.unwrap();
    assert_eq!(page.page, 2);
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn a_blank_search_asks_nothing() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "")));
    let page = source_over(http.clone())
        .search(SourceSearch::new("  "))
        .await
        .unwrap();
    assert!(page.items.is_empty());
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn adult_entries_never_reach_the_results() {
    let reply = json!({ "totalPages": 1, "results": [
        { "title": "Aman", "slug": "aman", "Rating": "PG-13" },
        { "title": "Dewasa", "slug": "dewasa", "Rating": "Rx - Hentai" },
        { "title": "Genre", "slug": "genre", "genres": ["Hentai"] },
    ] })
    .to_string();
    let http = Arc::new(FakeHttp::scripted(vec![ok(reply)]));
    let page = source_over(http)
        .search(SourceSearch::new("apa saja"))
        .await
        .unwrap();
    let ids: Vec<&str> = page.items.iter().map(|item| item.item_id.as_str()).collect();
    assert_eq!(ids, ["aman"]);
}

#[tokio::test]
async fn the_latest_list_is_paged_by_the_site() {
    let http = Arc::new(FakeHttp::scripted(vec![ok(fixtures::hianime("latest.json"))]));
    let page = source_over(http.clone()).latest(2).await.unwrap();
    assert_eq!(page.items.len(), 4);
    assert_eq!(page.total_pages, 322);
    assert!(http.requests()[0].url.ends_with("/api/latest/anime?page=2"));
}

#[tokio::test]
async fn the_detail_has_alternative_titles_year_and_episode_count() {
    let http = Arc::new(FakeHttp::scripted(vec![ok(fixtures::hianime("anime.json"))]));
    let detail = source_over(http.clone())
        .detail(ItemId::new(SLUG))
        .await
        .unwrap();
    assert_eq!(detail.item.item_id.as_str(), SLUG);
    assert_eq!(detail.unit_count, Some(8));
    assert_eq!(detail.year, Some(2026));
    assert!(!detail.alternative_titles.is_empty());
    assert!(!detail.synopsis.is_empty());
    let url = &http.requests()[0].url;
    assert!(url.starts_with("https://api.example.test/api/anime/steel-ball-run-jojo"));
}

#[tokio::test]
async fn a_slug_that_could_escape_its_segment_is_refused_before_any_request() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "")));
    let source = source_over(http.clone());
    for bad in ["../admin", "a/b", "", "a?b"] {
        let error = source.detail(ItemId::new(bad)).await.unwrap_err();
        assert!(matches!(error, SourceError::NotFound(_)), "{bad:?}");
    }
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn an_unknown_title_is_not_found_and_an_adult_one_is_hidden() {
    let missing = Arc::new(FakeHttp::always(HttpResponse::new(404, "")));
    assert!(matches!(
        source_over(missing).detail(ItemId::new("x")).await,
        Err(SourceError::NotFound(_))
    ));
    let adult = json!({ "anime": { "title": "A", "slug": "a", "Rating": "Rx - Hentai" } });
    let http = Arc::new(FakeHttp::scripted(vec![ok(adult.to_string())]));
    assert!(matches!(
        source_over(http).detail(ItemId::new("a")).await,
        Err(SourceError::NotFound(_))
    ));
}

#[tokio::test]
async fn a_page_that_is_not_json_is_a_markup_change() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "<main>x</main>")));
    let source = source_over(http);
    assert!(matches!(
        source.latest(1).await,
        Err(SourceError::MarkupChanged(_))
    ));
    assert!(matches!(
        source.search(SourceSearch::new("one piece")).await,
        Err(SourceError::MarkupChanged(_))
    ));
}
