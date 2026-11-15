use domain::error::SourceError;
use url::Url;

use super::listing::parse_listing_page;
use crate::fixtures;

fn site() -> Url {
    Url::parse("https://komiku.org").unwrap()
}

#[test]
fn parses_a_genre_listing_with_ids_titles_covers_labels_and_the_next_page_signal() {
    let page = parse_listing_page(&fixtures::komiku("listing-genre.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 10);
    let first = &page.items[0];
    assert!(!first.item_id.as_str().is_empty() && !first.title.is_empty());
    assert!(first.cover_url.as_deref().unwrap().starts_with("https:"));
    assert!(
        first
            .latest_label
            .as_deref()
            .unwrap()
            .starts_with("Chapter ")
    );
    assert!(page.has_next_page);
}

#[test]
fn parses_the_newest_updates_listing() {
    let page = parse_listing_page(&fixtures::komiku("listing-latest.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 10);
}

#[test]
fn parses_search_results_which_have_no_next_page() {
    let page = parse_listing_page(&fixtures::komiku("listing-search.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 1);
    let item = &page.items[0];
    assert_eq!(item.item_id.as_str(), "123213-chainsaw-man");
    assert_eq!(item.title, "Chainsaw Man");
    assert!(item.cover_url.as_deref().unwrap().contains("chainsaw-man"));
    assert_eq!(item.latest_label.as_deref(), Some("Chapter 232"));
    assert!(!page.has_next_page);
}

#[test]
fn accepts_an_empty_result_but_not_an_unknown_page() {
    let empty = parse_listing_page("", &site()).unwrap();
    assert!(empty.items.is_empty() && !empty.has_next_page);
    let unknown = parse_listing_page("<html><body><h1>Error 500</h1></body></html>", &site());
    assert!(matches!(unknown, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn the_sites_no_results_notice_is_an_empty_list_not_a_markup_change() {
    let page = parse_listing_page(&fixtures::komiku("listing-no-results.html"), &site()).unwrap();
    assert!(page.items.is_empty() && !page.has_next_page);
}

fn card(slug: &str, theme: &str) -> String {
    format!(
        r#"<div class="bge"><div class="bgei"><a href="/manga/{slug}/"><img src="https://x.test/{slug}.jpg"><div class="tpe1_inf"><b>Manga</b> {theme}</div></a></div><div class="kan"><h3>{slug}</h3></div></div>"#
    )
}

#[test]
fn drops_cards_of_adult_themes() {
    let html = format!(
        r#"<div class="hx">{}{}{}</div>"#,
        card("a-ok", "Horor"),
        card("b-adult", "Adult"),
        card("c-hentai", "Hentai")
    );
    let page = parse_listing_page(&html, &site()).unwrap();
    let ids: Vec<&str> = page
        .items
        .iter()
        .map(|item| item.item_id.as_str())
        .collect();
    assert_eq!(ids, vec!["a-ok"]);
}

#[test]
fn a_page_of_only_adult_cards_is_an_empty_list_not_a_markup_change() {
    let html = format!(r#"<div class="hx">{}</div>"#, card("b-adult", "Adult"));
    assert!(parse_listing_page(&html, &site()).unwrap().items.is_empty());
}

#[test]
fn cards_that_all_lack_a_title_are_a_markup_change() {
    let html = r#"<div class="bge"><div class="bgei"><a href="/manga/x/"></a></div><div class="kan"></div></div>"#;
    assert!(matches!(
        parse_listing_page(html, &site()),
        Err(SourceError::MarkupChanged(_))
    ));
}

#[test]
fn the_cover_falls_back_to_the_lazy_data_attribute() {
    let html = r#"<div class="bge"><div class="bgei"><a href="/manga/x/"><img data-src="/c.jpg"></a></div><div class="kan"><h3>X</h3></div></div>"#;
    let page = parse_listing_page(html, &site()).unwrap();
    assert_eq!(
        page.items[0].cover_url.as_deref(),
        Some("https://komiku.org/c.jpg")
    );
}
