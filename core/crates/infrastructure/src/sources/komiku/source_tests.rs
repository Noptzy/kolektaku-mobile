use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceOrder, SourceSearch, StreamSupport};

use super::KomikuSource;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};

const SITE: &str = "https://komiku.example";
const API: &str = "https://api.komiku.example";

fn site() -> (KomikuSource, Arc<FakeHttp>) {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        let url = &request.url;
        let body = if url.starts_with(API) && url.contains("post_type=manga") {
            fixtures::komiku("listing-search.html")
        } else if url.starts_with(API) {
            fixtures::komiku("listing-genre.html")
        } else if url.contains("/genre/") {
            fixtures::komiku("genre-list.html")
        } else if url.contains("/manga/") {
            fixtures::komiku("detail.html")
        } else {
            fixtures::komiku("chapter.html")
        };
        Ok(HttpResponse::new(200, body))
    }));
    let source = KomikuSource::new(http.clone(), Arc::new(FakeClock::at(0)), SITE, API, 5).unwrap();
    (source, http)
}

#[test]
fn describes_itself_as_a_manga_source_with_pages() {
    let (source, _) = site();
    let info = source.info();
    assert_eq!(info.id.as_str(), "komiku");
    assert_eq!(info.kind, MediaKind::Manga);
    assert_eq!(info.capabilities.stream, StreamSupport::None);
    assert!(source.pages().is_some() && source.video().is_none());
}

#[tokio::test]
async fn latest_reads_the_api_listing_and_signals_more_pages() {
    let (source, http) = site();
    let page = source.latest(2).await.unwrap();
    assert_eq!(page.items.len(), 10);
    assert_eq!((page.page, page.total_pages), (2, 3));
    assert_eq!(
        http.requests()[0].url,
        format!("{API}/manga/page/2/?orderby=modified")
    );
}

#[tokio::test]
async fn search_returns_one_page_and_nothing_beyond_it() {
    let (source, http) = site();
    let found = source
        .search(SourceSearch::new("chainsaw man"))
        .await
        .unwrap();
    assert_eq!(found.items[0].title, "Chainsaw Man");
    assert_eq!(found.total_pages, 1);
    let mut second = SourceSearch::new("chainsaw man");
    second.page = 2;
    let none = source.search(second).await.unwrap();
    assert!(none.items.is_empty());
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn genres_and_genre_listings_work_and_bad_slugs_never_hit_the_network() {
    let (source, http) = site();
    assert!(source.genres().await.unwrap().len() > 90);
    let page = source
        .by_genre("action".into(), 1, SourceOrder::Az)
        .await
        .unwrap();
    assert_eq!(page.items.len(), 10);
    assert!(
        http.requests()[1]
            .url
            .ends_with("/genre/action/?orderby=title&order=asc")
    );
    let before = http.requests().len();
    let bad = source.by_genre("../x".into(), 1, SourceOrder::Newest).await;
    assert!(matches!(bad, Err(SourceError::NotFound(_))));
    assert_eq!(http.requests().len(), before);
}

#[tokio::test]
async fn detail_units_and_chapter_pages_follow_the_reading_flow() {
    let (source, http) = site();
    let item = ItemId::new("123213-chainsaw-man");
    assert_eq!(
        source.detail(item.clone()).await.unwrap().item.title,
        "Chainsaw Man"
    );
    let units = source.units(item).await.unwrap();
    assert_eq!(units.len(), 39);
    assert!(units.first().unwrap().number < units.last().unwrap().number);
    let pages = source
        .pages()
        .unwrap()
        .chapter_pages(units[0].id.clone())
        .await
        .unwrap();
    assert!(pages.pages.len() > 20);
    assert_eq!(http.requests().len(), 2);
    let invalid = source.pages().unwrap().chapter_pages("a/b".into()).await;
    assert!(matches!(invalid, Err(SourceError::NotFound(_))));
}

#[tokio::test]
async fn a_series_page_without_chapters_is_a_markup_change_for_units() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "<h1>Komik X</h1>")));
    let source = KomikuSource::new(http, Arc::new(FakeClock::at(0)), SITE, API, 1).unwrap();
    let result = source.units(ItemId::new("x")).await;
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[tokio::test]
async fn http_problems_become_typed_errors() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(404, "")));
    let source = KomikuSource::new(http, Arc::new(FakeClock::at(0)), SITE, API, 1).unwrap();
    assert!(matches!(
        source.latest(1).await,
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        source.detail(ItemId::new("../x")).await,
        Err(SourceError::NotFound(_))
    ));
}

#[test]
fn refuses_addresses_that_are_not_web_addresses() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "")));
    let result = KomikuSource::new(http, Arc::new(FakeClock::at(0)), "nonsense", API, 1);
    assert!(matches!(result, Err(SourceError::Unsupported(_))));
}
