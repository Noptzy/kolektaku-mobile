use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceSearch, TextBlock};

use super::contract::site;
use super::registration::REGISTRATION;
use crate::fixtures;
use crate::http::{FakeHttp, HttpMethod, HttpRequest, HttpResponse};
use crate::sources::contract::{serving, source_over};

fn source_over_fixtures() -> (Arc<dyn SourceProvider>, Arc<FakeHttp>) {
    let http = serving(&site());
    (source_over(&REGISTRATION, http.clone()), http)
}

#[test]
fn it_describes_itself_as_a_text_source_for_novels() {
    let (source, _) = source_over_fixtures();
    let info = source.info();
    assert_eq!(info.kind, MediaKind::Novel);
    assert!(info.summary.contains("Indonesia"));
    assert!(source.texts().is_some());
    assert!(source.pages().is_none() && source.video().is_none());
}

#[tokio::test]
async fn searching_asks_the_site_once_and_reads_the_cards() {
    let (source, http) = source_over_fixtures();
    let page = source
        .search(SourceSearch::new("mushoku tensei"))
        .await
        .unwrap();
    assert_eq!(page.items.len(), 9);
    let requests = http.requests();
    assert_eq!(requests.len(), 1);
    assert!(requests[0].url.contains("s=mushoku+tensei"));
}

#[tokio::test]
async fn a_search_beyond_the_first_page_is_empty_without_asking() {
    let (source, http) = source_over_fixtures();
    let mut search = SourceSearch::new("mushoku tensei");
    search.page = 2;
    assert!(source.search(search).await.unwrap().items.is_empty());
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn the_chapter_list_is_asked_with_a_post_and_read_from_the_first_chapter() {
    let (source, http) = source_over_fixtures();
    let units = source
        .units(ItemId::new("mushoku-tensei-ln"))
        .await
        .unwrap();
    assert_eq!(units.len(), 60);
    assert_eq!(units[0].number, 1.0);
    let request: HttpRequest = http.requests().remove(0);
    assert_eq!(request.method, HttpMethod::Post);
    assert!(request.url.ends_with("/novel/mushoku-tensei-ln/ajax/chapters/"));
}

#[tokio::test]
async fn a_chapter_is_read_as_text_with_its_language() {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        let wanted = request
            .url
            .ends_with("/novel/mushoku-tensei-ln/volume-1-chapter-0/");
        Ok(match wanted {
            true => HttpResponse::new(200, fixtures::meionovels("chapter-illustrated.html")),
            false => HttpResponse::new(404, ""),
        })
    }));
    let source = source_over(&REGISTRATION, http);
    let text = source
        .texts()
        .unwrap()
        .chapter_text("mushoku-tensei-ln/volume-1-chapter-0".into())
        .await
        .unwrap();
    assert_eq!(text.language, "id");
    assert!(text.blocks.iter().any(|block| matches!(block, TextBlock::Image(_))));
}

#[tokio::test]
async fn a_bad_chapter_id_is_refused_without_a_request() {
    let (source, http) = source_over_fixtures();
    let result = source.texts().unwrap().chapter_text("../x".into()).await;
    assert!(matches!(result, Err(SourceError::NotFound(_))));
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn a_chapter_list_page_with_no_chapters_is_a_markup_change() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "<main>x</main>")));
    let source = source_over(&REGISTRATION, http);
    let result = source.units(ItemId::new("mushoku-tensei-ln")).await;
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}
