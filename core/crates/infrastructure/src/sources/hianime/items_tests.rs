use serde_json::json;

use super::items::{detail_of, item_of, items_of, year_of};
use super::model::RawAnime;

fn raw(value: serde_json::Value) -> RawAnime {
    serde_json::from_value(value).unwrap()
}

fn steel() -> RawAnime {
    raw(json!({
        "title": "Steel Ball Run: JoJo's Bizarre Adventure 2nd Stage",
        "English": "Steel Ball Run: JoJo's Bizarre Adventure 2nd Stage",
        "Japanese": "ジョジョの奇妙な冒険",
        "alternateTitle": "STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE",
        "slug": "steel-ball-run-2nd-13m7yk",
        "image": "https://img.test/a.jpg",
        "genres": ["Action", "Adventure"],
        "Type": "ONA", "totalEpisodes": "8", "totalSubbed": 8,
        "Aired": "2026-09-25", "Rating": "PG-13",
        "synopsis": "  Balapan.  "
    }))
}

#[test]
fn an_entry_becomes_an_item_with_its_slug_as_the_id() {
    let item = item_of(&steel()).unwrap();
    assert_eq!(item.item_id.as_str(), "steel-ball-run-2nd-13m7yk");
    assert_eq!(item.title, "Steel Ball Run: JoJo's Bizarre Adventure 2nd Stage");
    assert_eq!(item.cover_url.as_deref(), Some("https://img.test/a.jpg"));
    assert_eq!(item.latest_label.as_deref(), Some("Episode 8"));
}

#[test]
fn the_first_alias_is_used_when_there_is_no_main_slug() {
    let item = item_of(&raw(json!({ "title": "A", "slugs": ["a-1", "a-2"] }))).unwrap();
    assert_eq!(item.item_id.as_str(), "a-1");
}

#[test]
fn entries_without_a_usable_slug_or_title_are_dropped() {
    assert!(item_of(&raw(json!({ "title": "A" }))).is_none());
    assert!(item_of(&raw(json!({ "slug": "a" }))).is_none());
    assert!(item_of(&raw(json!({ "title": "A", "slug": "a/b" }))).is_none());
    assert!(item_of(&raw(json!({ "title": "  ", "slug": "a" }))).is_none());
}

#[test]
fn insecure_covers_are_not_kept() {
    let item = item_of(&raw(json!({ "title": "A", "slug": "a", "image": "http://img.test/a.jpg" }))).unwrap();
    assert_eq!(item.cover_url, None);
}

#[test]
fn adult_entries_never_become_items() {
    assert!(item_of(&raw(json!({ "title": "A", "slug": "a", "Rating": "Rx - Hentai" }))).is_none());
    assert!(item_of(&raw(json!({ "title": "A", "slug": "a", "Rating": " rx - hentai" }))).is_none());
    assert!(item_of(&raw(json!({ "title": "A", "slug": "a", "genres": ["Action", "Hentai"] }))).is_none());
    assert!(item_of(&raw(json!({ "title": "A", "slug": "a", "Rating": "R - 17+ (violence & profanity)" }))).is_some());
}

#[test]
fn uncensored_duplicates_come_after_the_plain_entries() {
    let items = items_of(Some(vec![
        raw(json!({ "title": "JoJo (Uncensored)", "slug": "u" })),
        raw(json!({ "title": "JoJo", "slug": "p" })),
    ]));
    let ids: Vec<&str> = items.iter().map(|item| item.item_id.as_str()).collect();
    assert_eq!(ids, ["p", "u"]);
    assert!(items_of(None).is_empty());
}

fn release(title: &str, slug: &str, mal: u64) -> serde_json::Value {
    json!({
        "title": title, "slug": slug, "mal_id": mal, "Aired": "Jul 18, 2025",
        "Type": "Movie", "totalEpisodes": 1, "Japanese": "Mugenjou-hen"
    })
}

fn dated(title: &str, slug: &str, created: &str) -> serde_json::Value {
    let mut value = release(title, slug, 59192);
    value["createdAt"] = json!(created);
    value
}

#[test]
fn of_two_listings_of_one_release_the_newer_video_keeps_the_plainer_name() {
    let items = items_of(Some(vec![
        raw(dated("Film - Part 1: Akaza Returns", "new-long", "2026-07-29T06:21:37.633Z")),
        raw(dated("Film", "old-plain", "2025-10-09T17:09:29.175Z")),
    ]));
    assert_eq!(items.len(), 1);
    assert_eq!(items[0].item_id.as_str(), "new-long");
    assert_eq!(items[0].title, "Film");
}

#[test]
fn the_order_the_site_lists_them_in_does_not_decide_which_is_newer() {
    let items = items_of(Some(vec![
        raw(dated("Film", "old-plain", "2025-10-09T17:09:29.175Z")),
        raw(dated("Film - Part 1: Akaza Returns", "new-long", "2026-07-29T06:21:37.633Z")),
    ]));
    assert_eq!(items[0].item_id.as_str(), "new-long");
    assert_eq!(items[0].title, "Film");
}

#[test]
fn without_dates_the_first_listing_stays_with_the_plainer_name() {
    let items = items_of(Some(vec![
        raw(release("Film Part 1", "first", 59192)),
        raw(release("Film", "second", 59192)),
    ]));
    assert_eq!(items.len(), 1);
    assert_eq!(items[0].item_id.as_str(), "first");
    assert_eq!(items[0].title, "Film");
}

#[test]
fn the_kept_listing_holds_the_place_of_the_first_one() {
    let items = items_of(Some(vec![
        raw(json!({ "title": "Before", "slug": "before" })),
        raw(release("Film Part 1", "long", 59192)),
        raw(release("Film", "plain", 59192)),
        raw(json!({ "title": "After", "slug": "after" })),
    ]));
    let ids: Vec<&str> = items.iter().map(|item| item.item_id.as_str()).collect();
    assert_eq!(ids, ["before", "long", "after"]);
}

#[test]
fn two_parts_sharing_a_catalog_number_but_not_a_release_are_both_kept() {
    let items = items_of(Some(vec![
        raw(json!({ "title": "Stage 1", "slug": "a", "mal_id": 61469, "Aired": "2026-01-01", "Type": "ONA", "totalEpisodes": 8 })),
        raw(json!({ "title": "Stage 2", "slug": "b", "mal_id": 61469, "Aired": "2026-09-25", "Type": "ONA", "totalEpisodes": 8 })),
    ]));
    assert_eq!(items.len(), 2);
}

#[test]
fn the_same_catalog_number_without_a_release_date_is_never_merged() {
    let items = items_of(Some(vec![
        raw(json!({ "title": "A", "slug": "a", "mal_id": 5 })),
        raw(json!({ "title": "B", "slug": "b", "mal_id": 5 })),
    ]));
    assert_eq!(items.len(), 2);
}

#[test]
fn the_same_title_listed_twice_is_offered_once() {
    let items = items_of(Some(vec![
        raw(release("Film Part 1", "first", 59192)),
        raw(release("Film", "second", 59192)),
        raw(json!({ "title": "Other", "slug": "other", "mal_id": 7, "Aired": "Jul 18, 2025" })),
    ]));
    let ids: Vec<&str> = items.iter().map(|item| item.item_id.as_str()).collect();
    assert_eq!(ids, ["first", "other"]);
}

#[test]
fn an_uncensored_copy_never_wins_over_the_plain_entry_of_the_same_title() {
    let items = items_of(Some(vec![
        raw(release("JoJo (Uncensored)", "u", 5)),
        raw(release("JoJo", "p", 5)),
    ]));
    let ids: Vec<&str> = items.iter().map(|item| item.item_id.as_str()).collect();
    assert_eq!(ids, ["p"]);
}

#[test]
fn entries_without_a_catalog_number_are_all_kept() {
    let items = items_of(Some(vec![
        raw(json!({ "title": "A", "slug": "a" })),
        raw(json!({ "title": "B", "slug": "b" })),
    ]));
    assert_eq!(items.len(), 2);
}

#[test]
fn the_year_is_found_in_either_date_style() {
    assert_eq!(year_of("Oct 7, 2025 to ?"), Some(2025));
    assert_eq!(year_of("2026-09-25"), Some(2026));
    assert_eq!(year_of("Apr 5, 2014 to Sep 13, 2014"), Some(2014));
    assert_eq!(year_of("?"), None);
    assert_eq!(year_of("Mar 3000"), None);
}

#[test]
fn the_detail_carries_alternative_titles_year_and_counts() {
    let detail = detail_of(&steel()).unwrap();
    assert_eq!(detail.year, Some(2026));
    assert_eq!(detail.unit_count, Some(8));
    assert_eq!(detail.type_text.as_deref(), Some("ONA"));
    assert_eq!(detail.synopsis, "Balapan.");
    assert_eq!(detail.genres, ["Action", "Adventure"]);
    assert_eq!(detail.item.latest_label, None);
    assert_eq!(
        detail.alternative_titles,
        [
            "ジョジョの奇妙な冒険",
            "STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE"
        ]
    );
}

#[test]
fn the_detail_carries_the_mal_number_of_the_site_entry() {
    let with = detail_of(&raw(json!({ "title": "A", "slug": "a", "mal_id": "38000" }))).unwrap();
    assert_eq!(with.mal_id, Some(38000));
    let without = detail_of(&raw(json!({ "title": "A", "slug": "a" }))).unwrap();
    assert_eq!(without.mal_id, None);
}
