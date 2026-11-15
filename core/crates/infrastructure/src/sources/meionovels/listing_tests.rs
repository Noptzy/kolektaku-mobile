use domain::error::SourceError;
use url::Url;

use super::listing::{novel_slug, parse_listing_page};
use crate::fixtures;

fn site() -> Url {
    Url::parse("https://meionovels.com").unwrap()
}

#[test]
fn search_results_have_a_clean_title_slug_and_cover() {
    let page = parse_listing_page(&fixtures::meionovels("search.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 9);
    let first = &page.items[0];
    assert_eq!(first.item_id.as_str(), "mushoku-tensei-ln");
    assert_eq!(first.title, "Mushoku Tensei");
    assert!(first.cover_url.as_deref().unwrap().starts_with("https://"));
    assert_eq!(first.latest_label, None);
}

#[test]
fn a_title_with_and_without_the_light_novel_mark_both_stay_listed() {
    let page = parse_listing_page(&fixtures::meionovels("search.html"), &site()).unwrap();
    let ids: Vec<&str> = page
        .items
        .iter()
        .map(|item| item.item_id.as_str())
        .collect();
    assert!(ids.contains(&"no-game-no-life-ln"));
    assert!(ids.contains(&"no-game-no-life"));
    let same: Vec<&str> = page
        .items
        .iter()
        .filter(|item| item.title == "No Game No Life")
        .map(|item| item.item_id.as_str())
        .collect();
    assert_eq!(same.len(), 2);
}

#[test]
fn the_latest_list_names_the_newest_chapter_and_knows_if_more_follow() {
    let page = parse_listing_page(&fixtures::meionovels("latest.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 12);
    assert!(page.has_next_page);
    let first = &page.items[0];
    assert_eq!(first.item_id.as_str(), "make-heroine-ga-oosugiru-ln");
    assert_eq!(first.title, "Make Heroine ga Oosugiru!");
    assert_eq!(
        first.latest_label.as_deref(),
        Some("Volume 8.5 SS Chapter 45")
    );
}

#[test]
fn a_percent_encoded_slug_is_read_whole() {
    let page = parse_listing_page(&fixtures::meionovels("latest.html"), &site()).unwrap();
    let encoded = page
        .items
        .iter()
        .find(|item| item.item_id.as_str().starts_with("magical%e2%98%85"))
        .unwrap();
    assert!(encoded.item_id.as_str().ends_with("-ln"));
}

#[test]
fn slugs_are_read_from_the_novel_path_only() {
    assert_eq!(
        novel_slug("https://meionovels.com/novel/a-b/").as_deref(),
        Some("a-b")
    );
    assert_eq!(
        novel_slug("https://meionovels.com/novel/a-b/volume-1-chapter-2/").as_deref(),
        Some("a-b")
    );
    assert_eq!(novel_slug("https://meionovels.com/genre/a-b/"), None);
}

#[test]
fn the_no_results_page_is_an_empty_list_not_a_markup_change() {
    let page = parse_listing_page(&fixtures::meionovels("search-empty.html"), &site()).unwrap();
    assert!(page.items.is_empty() && !page.has_next_page);
    let blank = parse_listing_page("", &site()).unwrap();
    assert!(blank.items.is_empty());
}

#[test]
fn an_unknown_page_is_a_markup_change() {
    let result = parse_listing_page("<main>redesigned</main>", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

fn card(slug: &str, genres: &str) -> String {
    format!(
        r#"<div class="row c-tabs-item__content"><div class="post-title"><h3 class="h4"><a href="https://meionovels.com/novel/{slug}/">Judul {slug}</a></h3></div><div class="post-content_item mg_genres"><div class="summary-content">{genres}</div></div></div>"#
    )
}

#[test]
fn cards_of_adult_genres_are_dropped() {
    let html = format!(
        "{}{}",
        card("aman", r#"<a href="/g/">Romance</a>, <a href="/g/">Mature</a>"#),
        card("dewasa", r#"<a href="/g/">Romance</a>, <a href="/g/">Smut</a>"#)
    );
    let page = parse_listing_page(&html, &site()).unwrap();
    let ids: Vec<&str> = page
        .items
        .iter()
        .map(|item| item.item_id.as_str())
        .collect();
    assert_eq!(ids, vec!["aman"]);
}

#[test]
fn a_page_of_only_adult_cards_is_an_empty_list() {
    let html = card("dewasa", r#"<a href="/g/">Adult</a>"#);
    let page = parse_listing_page(&html, &site()).unwrap();
    assert!(page.items.is_empty());
}
