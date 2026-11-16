use domain::error::SourceError;

use super::detail::{looks_like_a_detail_page, parse_detail};
use super::episodes::parse_units;
use super::listing::parse_listing;
use super::urls::GogoanimeUrls;
use crate::fixtures;

fn urls() -> GogoanimeUrls {
    GogoanimeUrls::new("https://gogoanime.or.at").unwrap()
}

#[test]
fn a_listing_gives_every_card_with_its_slug_title_and_cover() {
    let page = parse_listing(&fixtures::gogoanime("latest.html"), &urls(), 1).unwrap();
    assert_eq!(page.items.len(), 6);
    let first = &page.items[0];
    assert_eq!(
        first.item_id.as_str(),
        "hello-i-am-a-witch-and-my-crush-wants-me-to-make-a-love-potion"
    );
    assert!(first.title.to_lowercase().contains("witch"));
    assert!(first.cover_url.as_deref().unwrap().starts_with("https://gogoanime.or.at/wp-content/"));
}

#[test]
fn a_status_word_is_not_a_latest_label() {
    let page = parse_listing(&fixtures::gogoanime("latest.html"), &urls(), 1).unwrap();
    assert!(page.items.iter().all(|item| item.latest_label.is_none()));
}

#[test]
fn a_next_link_means_one_more_page_and_its_absence_means_the_last() {
    let more = parse_listing(&fixtures::gogoanime("latest.html"), &urls(), 3).unwrap();
    assert_eq!(more.total_pages, 4);
    let last = parse_listing(&fixtures::gogoanime("latest-last.html"), &urls(), 7).unwrap();
    assert_eq!(last.total_pages, 7);
}

#[test]
fn numbered_pagination_gives_the_last_page_number() {
    let page = parse_listing(&fixtures::gogoanime("search-page2.html"), &urls(), 2).unwrap();
    assert_eq!(page.total_pages, 2);
    assert_eq!(page.items.len(), 1);
}

#[test]
fn a_dub_card_keeps_its_own_slug_and_title() {
    let page = parse_listing(&fixtures::gogoanime("search.html"), &urls(), 1).unwrap();
    let dub = page
        .items
        .iter()
        .find(|item| item.item_id.as_str().ends_with("-dub"))
        .expect("a dub card");
    assert!(dub.title.contains("(Dub)"));
}

#[test]
fn a_search_without_matches_is_an_empty_page_not_an_error() {
    let page = parse_listing(&fixtures::gogoanime("search-empty.html"), &urls(), 1).unwrap();
    assert!(page.items.is_empty());
    assert_eq!(page.total_pages, 1);
}

#[test]
fn a_page_without_a_listing_is_a_markup_change() {
    let error = parse_listing("<html><body>redesigned</body></html>", &urls(), 1).unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[test]
fn cards_that_cannot_be_read_are_a_markup_change() {
    let html = "<div class=\"listupd\"><article class=\"bs\"><div>no link</div></article></div>";
    let error = parse_listing(html, &urls(), 1).unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[test]
fn a_detail_page_gives_the_facts_the_app_shows() {
    let detail = parse_detail(
        &fixtures::gogoanime("detail.html"),
        "oshi-no-ko-season-2",
        &urls(),
    )
    .unwrap();
    assert_eq!(detail.item.title, "[Oshi No Ko] Season 2");
    assert_eq!(detail.type_text.as_deref(), Some("TV"));
    assert_eq!(detail.year, Some(2024));
    assert_eq!(detail.unit_count, Some(13));
    assert!(detail.genres.contains(&"Drama".to_string()));
    assert!(detail.alternative_titles.contains(&"My Star Season 2".to_string()));
    assert!(!detail.alternative_titles.contains(&"[Oshi No Ko] Season 2".to_string()));
    assert!(detail.synopsis.starts_with("With the help of producer"));
    assert_eq!(detail.item.latest_label.as_deref(), Some("Episode 13"));
    assert!(detail.item.cover_url.is_some());
}

#[test]
fn a_page_that_is_not_a_detail_page_is_a_markup_change() {
    let error = parse_detail("<html></html>", "x", &urls()).unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
    assert!(!looks_like_a_detail_page("<html></html>"));
    assert!(looks_like_a_detail_page(&fixtures::gogoanime("detail.html")));
}

#[test]
fn episodes_are_listed_oldest_first_with_their_page_slugs() {
    let units = parse_units(&fixtures::gogoanime("detail.html"));
    assert_eq!(units.len(), 13);
    assert_eq!(units[0].number, 1.0);
    assert_eq!(units[0].label, "Episode 1");
    assert_eq!(units[0].id, "oshi-no-ko-season-2-episode-1");
    assert_eq!(units[12].number, 13.0);
    assert!(units.windows(2).all(|pair| pair[0].number < pair[1].number));
}

#[test]
fn a_decimal_episode_keeps_its_fraction_and_a_repeat_is_listed_once() {
    let html = "<div class=\"eplister\"><ul>\
        <li><a href=\"https://gogoanime.or.at/x-episode-5-5/\"><div class=\"epl-num\">5.5</div></a></li>\
        <li><a href=\"https://gogoanime.or.at/x-episode-5/\"><div class=\"epl-num\">5</div></a></li>\
        <li><a href=\"https://gogoanime.or.at/x-episode-5/\"><div class=\"epl-num\">5</div></a></li>\
        <li><a href=\"https://gogoanime.or.at/x-special/\"><div class=\"epl-num\">Special</div></a></li>\
        </ul></div>";
    let units = parse_units(html);
    let numbers: Vec<f64> = units.iter().map(|unit| unit.number).collect();
    assert_eq!(numbers, vec![5.0, 5.5]);
    assert_eq!(units[1].label, "Episode 5.5");
}
