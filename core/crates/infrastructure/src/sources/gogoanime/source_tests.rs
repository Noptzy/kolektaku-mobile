use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceSearch, StreamSupport};

use super::source::GogoanimeSource;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};

const BASE: &str = "https://gogoanime.or.at";

pub fn source_over(http: Arc<FakeHttp>) -> GogoanimeSource {
    GogoanimeSource::new(http, Arc::new(FakeClock::at(0)), BASE, 3).unwrap()
}

fn serving(route: fn(&str) -> Option<String>) -> Arc<FakeHttp> {
    Arc::new(FakeHttp::replying(move |request: &HttpRequest| {
        Ok(match route(&request.url) {
            Some(body) => HttpResponse::new(200, body),
            None => HttpResponse::new(404, ""),
        })
    }))
}

fn pages(url: &str) -> Option<String> {
    if url.contains("/anime/oshi-no-ko-season-2/") {
        Some(fixtures::gogoanime("detail.html"))
    } else if url.contains("/anime/?") {
        Some(fixtures::gogoanime("latest.html"))
    } else if url.contains("?s=oshi") {
        Some(fixtures::gogoanime("search.html"))
    } else if url.contains("?s=none") {
        Some(fixtures::gogoanime("search-empty.html"))
    } else {
        None
    }
}

#[test]
fn the_source_describes_itself_for_the_settings_screen() {
    let source = source_over(serving(pages));
    let info = source.info();
    assert_eq!(info.id.as_str(), "gogoanime");
    assert_eq!(info.kind, MediaKind::Anime);
    assert_eq!(info.priority, 3);
    assert_eq!(info.capabilities.stream, StreamSupport::NeedsWebView);
    assert!(info.capabilities.search && info.capabilities.latest);
    assert!(!info.capabilities.genres);
    assert!(info.summary.contains("Inggris"));
}

#[tokio::test]
async fn the_latest_page_lists_titles_and_knows_there_is_more() {
    let http = serving(pages);
    let page = source_over(http.clone()).latest(1).await.unwrap();
    assert_eq!(page.items.len(), 6);
    assert_eq!((page.page, page.total_pages), (1, 2));
    assert!(http.requests()[0].url.starts_with("https://gogoanime.or.at/anime/?"));
}

#[tokio::test]
async fn a_search_asks_the_site_for_the_query_and_lists_the_matches() {
    let http = serving(pages);
    let page = source_over(http.clone())
        .search(SourceSearch::new("oshi no ko"))
        .await
        .unwrap();
    assert_eq!(page.items.len(), 3);
    assert_eq!(http.requests()[0].url, "https://gogoanime.or.at/?s=oshi+no+ko");
}

#[tokio::test]
async fn a_search_with_no_match_is_an_empty_page() {
    let page = source_over(serving(pages))
        .search(SourceSearch::new("none"))
        .await
        .unwrap();
    assert!(page.items.is_empty());
}

#[tokio::test]
async fn a_title_gives_its_detail_and_its_episodes() {
    let source = source_over(serving(pages));
    let detail = source.detail(ItemId::new("oshi-no-ko-season-2")).await.unwrap();
    assert_eq!(detail.item.title, "[Oshi No Ko] Season 2");
    let units = source.units(ItemId::new("oshi-no-ko-season-2")).await.unwrap();
    assert_eq!(units.len(), 13);
}

#[tokio::test]
async fn an_unsafe_title_is_refused_without_a_request() {
    let http = serving(pages);
    let source = source_over(http.clone());
    for bad in ["../secret", "a/b", "a?b", ""] {
        let error = source.detail(ItemId::new(bad)).await.unwrap_err();
        assert!(matches!(error, SourceError::NotFound(_)), "{bad}");
        assert!(source.units(ItemId::new(bad)).await.is_err());
    }
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn a_page_that_lost_its_episode_list_is_a_markup_change() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "<html></html>")));
    let error = source_over(http)
        .units(ItemId::new("anything"))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[tokio::test]
async fn a_dead_site_is_reported_as_unavailable() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(522, "error code: 522")));
    let error = source_over(http).latest(1).await.unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}
