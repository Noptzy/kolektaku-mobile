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

const MEDALIST: &str = "01J76XYEB4BNMXCR7TP6YY0VN0/Medalist";

fn source_over_fixtures() -> (Arc<dyn SourceProvider>, Arc<FakeHttp>) {
    let http = serving(&site());
    (source_over(&REGISTRATION, http.clone()), http)
}

#[test]
fn it_is_a_comic_source_that_ranks_last_and_says_it_is_in_english() {
    let (source, _) = source_over_fixtures();
    let info = source.info();
    assert_eq!(info.kind, MediaKind::Manga);
    assert_eq!(info.summary, "Bahasa Inggris");
    assert!(info.priority >= 9);
    assert!(source.pages().is_some() && source.texts().is_none());
}

#[tokio::test]
async fn the_search_asks_for_the_text_without_adult_titles() {
    let (source, http) = source_over_fixtures();
    source.search(SourceSearch::new("medalist")).await.unwrap();
    let url = http.requests().remove(0).url;
    assert!(url.contains("text=medalist"));
    assert!(url.contains("adult=False"));
}

#[tokio::test]
async fn a_detail_names_the_catalog_number_for_exact_matching() {
    let (source, _) = source_over_fixtures();
    let detail = source.detail(ItemId::new(MEDALIST)).await.unwrap();
    assert_eq!(detail.catalog_id, Some(118371));
}

#[tokio::test]
async fn the_chapters_are_asked_once_and_read_from_the_first() {
    let (source, http) = source_over_fixtures();
    let units = source.units(ItemId::new(MEDALIST)).await.unwrap();
    assert_eq!(units.len(), 40);
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn a_chapter_is_read_as_its_image_addresses() {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        let wanted = request
            .url
            .contains("/chapters/01M5T2RTHVV4MYP080PTQF8G97/images");
        Ok(match wanted {
            true => HttpResponse::new(200, fixtures::weebcentral("images.html")),
            false => HttpResponse::new(404, ""),
        })
    }));
    let source = source_over(&REGISTRATION, http);
    let pages = source
        .pages()
        .unwrap()
        .chapter_pages("01M5T2RTHVV4MYP080PTQF8G97".into())
        .await
        .unwrap();
    assert_eq!(pages.pages.len(), 34);
}

#[tokio::test]
async fn a_bad_chapter_id_is_refused_without_a_request() {
    let (source, http) = source_over_fixtures();
    let result = source.pages().unwrap().chapter_pages("../x".into()).await;
    assert!(matches!(result, Err(SourceError::NotFound(_))));
    assert!(http.requests().is_empty());
}
