use domain::error::SourceError;
use url::Url;

use super::detail::parse_detail;
use super::listing::parse_listing_page;
use crate::fixtures;

fn site() -> Url {
    Url::parse("https://novelphoenix.com").unwrap()
}

#[test]
fn search_results_have_a_slug_title_cover_and_chapter_count() {
    let page = parse_listing_page(&fixtures::novelphoenix("search.html"), &site()).unwrap();
    assert_eq!(page.items.len(), 3);
    let first = &page.items[0];
    assert_eq!(first.item_id.as_str(), "the-beginning-after-the-end");
    assert_eq!(first.title, "The Beginning After The End");
    assert_eq!(
        first.cover_url.as_deref(),
        Some("https://novelphoenix.com/server-1/the-beginning-after-the-end.jpg")
    );
    assert_eq!(first.latest_label.as_deref(), Some("Ch. 532"));
}

#[test]
fn look_alike_titles_stay_separate_items() {
    let page = parse_listing_page(&fixtures::novelphoenix("search.html"), &site()).unwrap();
    let ids: Vec<&str> = page
        .items
        .iter()
        .map(|item| item.item_id.as_str())
        .collect();
    assert!(ids.contains(&"discordant-note-the-beginning-after-the-end-si"));
}

#[test]
fn an_empty_or_unknown_page_is_told_apart() {
    assert!(
        parse_listing_page("", &site())
            .unwrap()
            .items
            .is_empty()
    );
    let result = parse_listing_page("<main>redesigned</main>", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn the_detail_reads_title_count_genres_and_synopsis() {
    let detail = parse_detail(
        &fixtures::novelphoenix("detail.html"),
        "the-beginning-after-the-end",
        &site(),
    )
    .unwrap();
    assert_eq!(detail.item.title, "The Beginning After The End");
    assert_eq!(detail.unit_count, Some(532));
    assert_eq!(detail.genres, vec!["Fantasy", "Martial Arts"]);
    assert_eq!(detail.type_text.as_deref(), Some("Web Novel"));
    assert!(detail.synopsis.starts_with("King Grey has unrivaled strength"));
    assert!(detail.synopsis.contains("\n\n"));
    assert!(detail.item.cover_url.as_deref().unwrap().ends_with(".jpg"));
    assert!(detail.alternative_titles.is_empty() && detail.year.is_none());
}

#[test]
fn a_page_without_a_title_is_a_markup_change() {
    let result = parse_detail("<main>redesigned</main>", "x", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn a_title_of_an_adult_genre_is_not_found() {
    let html = r#"<h1 class="novel-title">Judul</h1><div class="categories"><ul><li><a>Smut</a></li></ul></div>"#;
    let result = parse_detail(html, "judul", &site());
    assert!(matches!(result, Err(SourceError::NotFound(_))));
}
