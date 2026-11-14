use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceOrder, SourceSearch};

use super::KomikindoSource;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};

const BASE: &str = "https://komikindo.example";

fn source_with(status: u16) -> (KomikindoSource, Arc<FakeHttp>) {
    let http = Arc::new(FakeHttp::replying(move |request: &HttpRequest| {
        let url = &request.url;
        let name = if url.contains("?s=") {
            "search.html"
        } else if url.contains("/daftar-manga") {
            "filter.html"
        } else if url.contains("/komik/") {
            "detail.html"
        } else if url.contains("/komik-terbaru") {
            "latest.html"
        } else {
            "chapter.html"
        };
        let body = if status == 200 {
            fixtures::komikindo(name)
        } else {
            String::new()
        };
        Ok(HttpResponse::new(status, body))
    }));
    let source = KomikindoSource::new(http.clone(), Arc::new(FakeClock::at(0)), BASE, 8).unwrap();
    (source, http)
}

#[test]
fn describes_itself_as_a_backup_manga_source() {
    let (source, _) = source_with(200);
    assert_eq!(source.info().id.as_str(), "komikindo");
    assert_eq!(source.info().kind, MediaKind::Manga);
    assert_eq!(source.info().priority, 8);
    assert!(source.pages().is_some());
}

#[tokio::test]
async fn serves_the_whole_reading_flow() {
    let (source, _) = source_with(200);
    assert!(source.latest(1).await.unwrap().total_pages > 100);
    let search = source.search(SourceSearch::new("chainsaw")).await.unwrap();
    assert_eq!(search.items[0].item_id.as_str(), "chainsaw-man");
    let second = SourceSearch {
        page: 2,
        ..SourceSearch::new("chainsaw")
    };
    assert!(source.search(second).await.unwrap().items.is_empty());
    assert_eq!(source.genres().await.unwrap().len(), 3);
    assert_eq!(
        source
            .by_genre("action".into(), 1, SourceOrder::Newest)
            .await
            .unwrap()
            .total_pages,
        9
    );
    let units = source.units(ItemId::new("chainsaw-man")).await.unwrap();
    let numbers: Vec<f64> = units.iter().map(|unit| unit.number).collect();
    assert_eq!(numbers, vec![1.0, 2.0, 2.5, 3.0]);
    let pages = source
        .pages()
        .unwrap()
        .chapter_pages("chainsaw-man-chapter-1".into())
        .await
        .unwrap();
    assert_eq!(pages.pages.len(), 3);
}

#[tokio::test]
async fn the_downtime_it_is_known_for_is_reported_as_unavailable() {
    let (down, _) = source_with(522);
    assert!(matches!(
        down.search(SourceSearch::new("x")).await,
        Err(SourceError::Unavailable(_))
    ));
    assert!(matches!(
        down.detail(ItemId::new("a")).await,
        Err(SourceError::Unavailable(_))
    ));
}

#[tokio::test]
async fn bad_ids_are_refused_before_any_request() {
    let (source, http) = source_with(522);
    assert!(matches!(
        source.detail(ItemId::new("../x")).await,
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        source.pages().unwrap().chapter_pages("a/b".into()).await,
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        source.by_genre("../x".into(), 1, SourceOrder::Newest).await,
        Err(SourceError::NotFound(_))
    ));
    assert!(http.requests().is_empty());
}

#[test]
fn refuses_an_address_that_is_not_a_web_address() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "")));
    let result = KomikindoSource::new(http, Arc::new(FakeClock::at(0)), "nonsense", 1);
    assert!(matches!(result, Err(SourceError::Unsupported(_))));
}
