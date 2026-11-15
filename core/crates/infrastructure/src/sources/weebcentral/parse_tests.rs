use domain::error::SourceError;
use url::Url;

use super::chapter_pages::parse_chapter_pages;
use super::chapters::parse_chapter_list;
use super::detail::parse_detail;
use super::listing::parse_listing_page;
use crate::fixtures;

const MEDALIST: &str = "01J76XYEB4BNMXCR7TP6YY0VN0/Medalist";

fn site() -> Url {
    Url::parse("https://weebcentral.com").unwrap()
}

#[test]
fn search_results_carry_the_series_code_and_slug_once() {
    let page = parse_listing_page(&fixtures::weebcentral("search.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 6);
    let first = &page.items[0];
    assert_eq!(first.item_id.as_str(), MEDALIST);
    assert_eq!(first.title, "Medalist");
    assert!(first.cover_url.as_deref().unwrap().starts_with("https://"));
    let mut ids: Vec<&str> = page
        .items
        .iter()
        .map(|item| item.item_id.as_str())
        .collect();
    ids.sort_unstable();
    ids.dedup();
    assert_eq!(ids.len(), 6);
}

#[test]
fn a_warning_instead_of_cards_is_an_empty_list() {
    let page = parse_listing_page(&fixtures::weebcentral("search-empty.html"), &site()).unwrap();
    assert!(page.items.is_empty());
    assert!(parse_listing_page("", &site()).unwrap().items.is_empty());
}

#[test]
fn an_unknown_page_is_a_markup_change() {
    let result = parse_listing_page("<main>redesigned</main>", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn the_detail_names_the_catalog_entry_and_its_facts() {
    let detail = parse_detail(&fixtures::weebcentral("detail.html"), MEDALIST, &site()).unwrap();
    assert_eq!(detail.item.title, "Medalist");
    assert_eq!(detail.catalog_id, Some(118371));
    assert_eq!(detail.type_text.as_deref(), Some("Manga"));
    assert_eq!(detail.year, Some(2020));
    assert!(detail.genres.contains(&"Drama".to_string()));
    assert!(detail.synopsis.starts_with("Inori is a little girl"));
}

#[test]
fn a_detail_without_a_title_is_a_markup_change() {
    let result = parse_detail("<main>redesigned</main>", MEDALIST, &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn a_detail_without_a_catalog_link_names_no_number() {
    let html = "<h1>Judul</h1><ul><li><strong>Type: </strong><a>Manga</a></li></ul>";
    let detail = parse_detail(html, MEDALIST, &site()).unwrap();
    assert_eq!(detail.catalog_id, None);
    assert_eq!(detail.type_text.as_deref(), Some("Manga"));
}

#[test]
fn a_title_of_an_adult_tag_is_not_found() {
    let html = "<h1>Judul</h1><ul><li><strong>Tags(s): </strong><span><a>Smut</a></span></li></ul>";
    let result = parse_detail(html, MEDALIST, &site());
    assert!(matches!(result, Err(SourceError::NotFound(_))));
}

#[test]
fn the_chapter_list_is_sorted_from_the_first_chapter_with_their_numbers() {
    let units = parse_chapter_list(&fixtures::weebcentral("chapters.html"));
    assert_eq!(units.len(), 40);
    assert!(units.windows(2).all(|pair| pair[0].number < pair[1].number));
    let last = units.last().unwrap();
    assert_eq!(last.number, 59.0);
    assert_eq!(last.label, "Score 59");
    assert_eq!(last.id.len(), 26);
}

#[test]
fn a_volume_before_the_chapter_does_not_become_its_number() {
    let html = r#"<a href="/chapters/01M5T2RTHVV4MYP080PTQF8G97"><span class="grow"><span class="">Volume 3 Chapter 12.5</span></span></a>"#;
    let units = parse_chapter_list(html);
    assert_eq!(units[0].number, 12.5);
}

#[test]
fn links_that_are_not_chapters_are_ignored() {
    let html = r#"<a href="/series/x"><span class="grow"><span>Chapter 1</span></span></a><a href="/chapters/short"><span class="grow"><span>Chapter 2</span></span></a>"#;
    assert!(parse_chapter_list(html).is_empty());
}

#[test]
fn the_pages_are_the_chapter_images_in_order_without_the_placeholder() {
    let pages = parse_chapter_pages(&fixtures::weebcentral("images.html"), &site()).unwrap();
    assert_eq!(pages.pages.len(), 34);
    assert!(pages.pages[0].url.ends_with("0059-001.png"));
    assert!(pages.pages[33].url.ends_with("0059-034.png"));
    assert!(pages.pages.iter().all(|page| !page.url.contains("/static/")));
}

#[test]
fn a_chapter_without_images_is_a_markup_change() {
    let result = parse_chapter_pages("<main>redesigned</main>", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}
