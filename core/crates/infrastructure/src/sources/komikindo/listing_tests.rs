use domain::error::SourceError;
use url::Url;

use super::listing::parse_listing_page;
use crate::fixtures;

fn base() -> Url {
    Url::parse("https://komikindo.example").unwrap()
}

#[test]
fn parses_the_real_newest_chapters_page() {
    let html = fixtures::komikindo("latest.html");
    let page = parse_listing_page(&html, &Url::parse("https://komikindo.ch").unwrap()).unwrap();
    assert!(page.items.len() >= 30);
    let first = &page.items[0];
    assert!(!first.title.is_empty() && !first.item_id.as_str().is_empty());
    assert!(first.latest_label.as_deref().unwrap().starts_with("Ch. "));
    assert!(first.cover_url.as_deref().unwrap().starts_with("https:"));
    assert!(page.total_pages > 100);
}

#[test]
fn parses_search_and_filter_results() {
    let search = parse_listing_page(&fixtures::komikindo("search.html"), &base()).unwrap();
    let ids: Vec<&str> = search
        .items
        .iter()
        .map(|item| item.item_id.as_str())
        .collect();
    assert_eq!(ids, vec!["chainsaw-man", "chainsaw-man-gaiden"]);
    assert_eq!(search.items[0].title, "Chainsaw Man");
    assert_eq!(search.items[0].latest_label.as_deref(), Some("Ch. 232"));
    let filtered = parse_listing_page(&fixtures::komikindo("filter.html"), &base()).unwrap();
    assert_eq!(filtered.total_pages, 9);
}

#[test]
fn accepts_a_search_without_hits_but_rejects_an_unknown_page() {
    let none = parse_listing_page("<h1>Komik Hasil Pencarian</h1>", &base()).unwrap();
    assert!(none.items.is_empty());
    assert_eq!(none.total_pages, 1);
    let unknown = parse_listing_page("<main>changed</main>", &base());
    assert!(matches!(unknown, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn an_escaped_slug_is_decoded() {
    let html = r#"<div class="listupd"><div class="film-list"><div class="animepost"><div class="animposx">
        <a href="https://k.test/komik/%E3%83%81-title/"><img data-src="/c.jpg"></a>
        <div class="bigors"><div class="tt">Titel</div></div></div></div></div></div>"#;
    let page = parse_listing_page(html, &base()).unwrap();
    assert_eq!(page.items[0].item_id.as_str(), "チ-title");
    assert_eq!(
        page.items[0].cover_url.as_deref(),
        Some("https://komikindo.example/c.jpg")
    );
}

#[test]
fn a_list_whose_cards_are_all_unusable_is_a_markup_change() {
    let html = r#"<div class="listupd"><div class="film-list"><div class="animepost"><div class="animposx"><a href="/komik/x/"></a></div></div></div></div>"#;
    assert!(matches!(
        parse_listing_page(html, &base()),
        Err(SourceError::MarkupChanged(_))
    ));
}
