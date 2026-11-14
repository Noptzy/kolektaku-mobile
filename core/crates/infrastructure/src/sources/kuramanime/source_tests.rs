use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceOrder, SourceSearch, StreamSupport};

use super::KuramanimeSource;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};

const BASE: &str = "https://v20.kuramanime.example";

pub fn site(routes: Vec<(&'static str, String)>) -> (KuramanimeSource, Arc<FakeHttp>) {
    let http = Arc::new(FakeHttp::replying(move |request: &HttpRequest| {
        let page = routes
            .iter()
            .find(|(fragment, _)| request.url.contains(fragment))
            .map(|(_, body)| HttpResponse::new(200, body.clone()))
            .unwrap_or_else(|| HttpResponse::new(404, ""));
        Ok(page)
    }));
    let source = KuramanimeSource::new(http.clone(), Arc::new(FakeClock::at(0)), BASE, 3).unwrap();
    (source, http)
}

pub fn popover_page(episodes: std::ops::RangeInclusive<u32>, forward: bool) -> String {
    let links: String = episodes
        .map(|number| format!(r#"<a href="/anime/7/long/episode/{number}">Episode {number}</a>"#))
        .collect();
    let arrow = if forward {
        r#"<a class="page__link__episode" href="?page=2"><i class="fa fa-forward"></i></a>"#
    } else {
        ""
    };
    format!(
        r#"<div class="anime__details__title"><h3>Long</h3></div><a id="episodeLists" data-content='{links}{arrow}'>x</a>"#
    )
}

#[test]
fn describes_itself_as_a_streaming_anime_source() {
    let (source, _) = site(vec![]);
    let info = source.info();
    assert_eq!(info.id.as_str(), "kuramanime");
    assert_eq!(info.kind, MediaKind::Anime);
    assert_eq!(info.priority, 3);
    assert_eq!(info.capabilities.stream, StreamSupport::NeedsWebView);
    assert!(source.video().is_some() && source.pages().is_none());
}

#[test]
fn refuses_an_address_that_is_not_a_web_address() {
    let result = KuramanimeSource::new(
        Arc::new(FakeHttp::always(HttpResponse::new(200, ""))),
        Arc::new(FakeClock::at(0)),
        "nonsense",
        1,
    );
    assert!(matches!(result, Err(SourceError::Unsupported(_))));
}

#[tokio::test]
async fn latest_lists_the_ongoing_cards() {
    let (source, http) = site(vec![(
        "/quick/ongoing",
        fixtures::kuramanime("latest-page.html"),
    )]);
    let page = source.latest(2).await.unwrap();
    assert!(page.items.len() >= 10);
    assert_eq!(page.page, 2);
    assert!(page.total_pages > 1);
    assert_eq!(
        http.requests()[0].url,
        format!("{BASE}/quick/ongoing?order_by=updated&page=2")
    );
}

#[tokio::test]
async fn search_sends_the_query_and_the_order_and_may_find_nothing() {
    let (source, http) = site(vec![
        ("search=zzz", fixtures::kuramanime("empty-search.html")),
        ("search=one", fixtures::kuramanime("listing-small.html")),
    ]);
    let mut found = SourceSearch::new("one piece");
    found.order = SourceOrder::Az;
    let page = source.search(found).await.unwrap();
    assert_eq!(page.items[0].title, "One Piece");
    assert!(
        http.requests()[0]
            .url
            .contains("search=one+piece&order_by=ascending&page=1")
    );
    let nothing = source.search(SourceSearch::new("zzz")).await.unwrap();
    assert!(nothing.items.is_empty());
}

#[tokio::test]
async fn genres_and_genre_listings_work_and_bad_slugs_never_hit_the_network() {
    let (source, http) = site(vec![
        (
            "/properties/genre/action",
            fixtures::kuramanime("genre-page.html"),
        ),
        ("/properties/genre?", fixtures::kuramanime("genres.html")),
    ]);
    assert_eq!(source.genres().await.unwrap().len(), 77);
    let page = source
        .by_genre("action".into(), 2, SourceOrder::Oldest)
        .await
        .unwrap();
    assert!(page.items.len() >= 10);
    assert!(
        http.requests()[1]
            .url
            .ends_with("/properties/genre/action?order_by=oldest&page=2")
    );
    let before = http.requests().len();
    let bad = source
        .by_genre("../admin".into(), 1, SourceOrder::Newest)
        .await;
    assert!(matches!(bad, Err(SourceError::NotFound(_))));
    assert_eq!(http.requests().len(), before);
}

#[tokio::test]
async fn detail_reads_the_page_of_the_item() {
    let (source, http) = site(vec![(
        "/anime/50/one-piece",
        fixtures::kuramanime("detail-live.html"),
    )]);
    let detail = source.detail(ItemId::new("50/one-piece")).await.unwrap();
    assert_eq!(detail.item.title, "One Piece");
    assert_eq!(http.requests()[0].url, format!("{BASE}/anime/50/one-piece"));
    let invalid = source.detail(ItemId::new("https://evil.example/x")).await;
    assert!(matches!(invalid, Err(SourceError::NotFound(_))));
}

#[tokio::test]
async fn http_and_markup_problems_become_typed_errors() {
    let (missing, _) = site(vec![]);
    assert!(matches!(
        missing.latest(1).await,
        Err(SourceError::NotFound(_))
    ));
    let (changed, _) = site(vec![("/quick/ongoing", "<main>redesigned</main>".into())]);
    assert!(matches!(
        changed.latest(1).await,
        Err(SourceError::MarkupChanged(_))
    ));
    let down = Arc::new(FakeHttp::always(HttpResponse::new(502, "bad gateway")));
    let source = KuramanimeSource::new(down, Arc::new(FakeClock::at(0)), BASE, 1).unwrap();
    assert!(matches!(
        source.latest(1).await,
        Err(SourceError::Unavailable(_))
    ));
}
