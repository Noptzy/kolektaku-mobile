use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceSearch};

use super::contract::site;
use super::registration::REGISTRATION;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};
use crate::sources::contract::{serving, source_over};

fn source_over_fixtures() -> (Arc<dyn SourceProvider>, Arc<FakeHttp>) {
    let http = serving(&site());
    (source_over(&REGISTRATION, http.clone()), http)
}

#[test]
fn it_is_a_lower_priority_text_source_for_novels_in_english() {
    let (source, _) = source_over_fixtures();
    let info = source.info();
    assert_eq!(info.kind, MediaKind::Novel);
    assert!(info.summary.contains("Inggris"));
    assert!(info.priority > 5);
    assert!(source.texts().is_some() && source.pages().is_none());
}

#[tokio::test]
async fn every_page_of_the_chapter_list_is_asked_for() {
    let (source, http) = source_over_fixtures();
    source
        .units(ItemId::new("the-beginning-after-the-end"))
        .await
        .unwrap();
    let urls: Vec<String> = http.requests().into_iter().map(|r| r.url).collect();
    assert_eq!(urls.len(), 6);
    for page in 1..=6 {
        let wanted = format!("/novel/the-beginning-after-the-end/chapters?page={page}");
        assert!(urls.iter().any(|url| url.ends_with(&wanted)), "{page}");
    }
}

#[tokio::test]
async fn one_failing_list_page_fails_the_whole_list() {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        Ok(if request.url.ends_with("page=3") {
            HttpResponse::new(500, "")
        } else {
            HttpResponse::new(200, fixtures::novelphoenix("chapters.html"))
        })
    }));
    let source = source_over(&REGISTRATION, http);
    let result = source.units(ItemId::new("the-beginning-after-the-end")).await;
    assert!(matches!(result, Err(SourceError::Unavailable(_))));
}

#[tokio::test]
async fn a_search_beyond_the_first_page_is_empty_without_asking() {
    let (source, http) = source_over_fixtures();
    let mut search = SourceSearch::new("anything");
    search.page = 2;
    assert!(source.search(search).await.unwrap().items.is_empty());
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn a_chapter_is_read_as_english_text() {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        let wanted = request
            .url
            .ends_with("/novel/the-beginning-after-the-end/chapter-1");
        Ok(match wanted {
            true => HttpResponse::new(200, fixtures::novelphoenix("chapter.html")),
            false => HttpResponse::new(404, ""),
        })
    }));
    let source = source_over(&REGISTRATION, http);
    let text = source
        .texts()
        .unwrap()
        .chapter_text("the-beginning-after-the-end/chapter-1".into())
        .await
        .unwrap();
    assert_eq!(text.language, "en");
    assert_eq!(text.paragraphs().count(), 16);
}

#[tokio::test]
async fn a_bad_chapter_id_is_refused_without_a_request() {
    let (source, http) = source_over_fixtures();
    let result = source.texts().unwrap().chapter_text("../x".into()).await;
    assert!(matches!(result, Err(SourceError::NotFound(_))));
    assert!(http.requests().is_empty());
}
