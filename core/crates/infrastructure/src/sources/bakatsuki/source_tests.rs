use domain::source::{ItemId, SourceSearch};

use super::contract::site;
use crate::sources::contract::{always, serving, source_over};
use crate::sources::registry::REGISTRATIONS;

fn registration() -> &'static crate::sources::registry::Registration {
    REGISTRATIONS
        .iter()
        .find(|item| item.defaults.id == "bakatsuki")
        .copied()
        .unwrap()
}

#[tokio::test]
async fn a_chapter_is_read_by_its_page_title() {
    let source = source_over(registration(), serving(&site()));
    let units = source.units(ItemId::new("Hyouka")).await.unwrap();
    let text = source
        .texts()
        .unwrap()
        .chapter_text(units[0].id.clone())
        .await
        .unwrap();
    assert_eq!(text.language, "en");
    assert!(text.paragraphs().count() > 10);
}

#[tokio::test]
async fn searching_a_series_the_site_does_not_have_gives_an_empty_page() {
    let source = source_over(registration(), serving(&site()));
    let page = source
        .search(SourceSearch::new("zzzz not a series"))
        .await
        .unwrap();
    assert!(page.items.is_empty());
}

#[tokio::test]
async fn a_second_search_page_is_empty_without_asking_the_site() {
    let source = source_over(registration(), always(500, "down"));
    let mut search = SourceSearch::new("hyouka");
    search.page = 2;
    assert!(source.search(search).await.unwrap().items.is_empty());
}

#[tokio::test]
async fn a_dead_site_is_an_error_not_an_empty_answer() {
    let source = source_over(registration(), always(503, "down"));
    assert!(source.search(SourceSearch::new("hyouka")).await.is_err());
    assert!(source.units(ItemId::new("Hyouka")).await.is_err());
}

#[tokio::test]
async fn a_series_page_without_chapters_is_a_markup_change() {
    let source = source_over(registration(), always(200, "<main>redesigned</main>"));
    assert!(source.units(ItemId::new("Hyouka")).await.is_err());
}

#[tokio::test]
async fn an_unsafe_page_title_is_refused_before_any_request() {
    let source = source_over(registration(), always(200, "x"));
    assert!(source.detail(ItemId::new("a|b")).await.is_err());
}
