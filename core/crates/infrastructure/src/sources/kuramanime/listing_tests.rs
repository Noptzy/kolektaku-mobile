use domain::error::SourceError;
use url::Url;

use super::listing::parse_listing_page;
use crate::fixtures;

fn base() -> Url {
    Url::parse("https://kuramanime.example").unwrap()
}

fn live_base() -> Url {
    Url::parse("https://v20.kuramanime.ing").unwrap()
}

#[test]
fn parses_cards_and_reads_the_pagination() {
    let page = parse_listing_page(&fixtures::kuramanime("listing-small.html"), &base()).unwrap();
    assert_eq!(page.items.len(), 2);
    let first = &page.items[0];
    assert_eq!(first.item_id.as_str(), "50/one-piece");
    assert_eq!(first.title, "One Piece");
    assert_eq!(
        first.cover_url.as_deref(),
        Some("https://img.example/one-piece.jpg")
    );
    assert_eq!(first.latest_label.as_deref(), Some("Episode 1145"));
    assert_eq!(page.total_pages, 2);
}

#[test]
fn an_episode_link_is_normalized_to_the_anime_id_and_unknown_labels_are_hidden() {
    let html = r#"<div id="animeList"><div class="filter__gallery">
        <a href="/anime/50/one-piece-random/episode/1180">
          <div class="product__sidebar__view__item" data-setbg="/poster.jpg">
            <h5 class="sidebar-title-h5">One Piece</h5><div class="ep"><i></i><span> ? </span></div>
          </div>
        </a></div></div>"#;
    let page = parse_listing_page(html, &base()).unwrap();
    let item = &page.items[0];
    assert_eq!(item.item_id.as_str(), "50/one-piece-random");
    assert_eq!(item.latest_label, None);
    assert_eq!(
        item.cover_url.as_deref(),
        Some("https://kuramanime.example/poster.jpg")
    );
}

#[test]
fn parses_a_real_latest_page_of_the_older_layout() {
    let html = fixtures::kuramanime("latest-page.html");
    let page = parse_listing_page(&html, &live_base()).unwrap();
    assert!(page.items.len() >= 10);
    let label = page.items[0].latest_label.as_deref().unwrap();
    assert!(label.starts_with("Ep "), "{label}");
    assert!(page.total_pages > 1);
}

#[test]
fn parses_a_real_latest_page_of_the_current_layout() {
    let html = fixtures::kuramanime("latest-page-current.html");
    let page = parse_listing_page(&html, &live_base()).unwrap();
    assert!(page.items.len() >= 10);
    let first = &page.items[0];
    assert!(first.item_id.as_str().contains('/') && !first.item_id.as_str().contains("episode"));
    assert!(!first.title.is_empty());
    assert!(first.cover_url.as_deref().unwrap().starts_with("https:"));
    assert!(first.latest_label.as_deref().unwrap().starts_with("Ep "));
    assert!(page.total_pages >= 2);
}

#[test]
fn the_current_layout_card_is_read_from_its_heading_and_poster() {
    let html = r#"<div id="animeList"><div class="product__item">
        <a href="https://k.test/anime/5037/some-show/episode/20"><div class="product__item__pic set-bg" data-setbg="https://img.test/a.jpg">
          <div class="ep"><span>Ep 20 / 26</span></div></div></a>
        <div class="product__item__text"><h5><a href="https://k.test/anime/5037/some-show/episode/20">Some  Show</a></h5></div>
      </div></div>"#;
    let item = &parse_listing_page(html, &base()).unwrap().items[0];
    assert_eq!(item.item_id.as_str(), "5037/some-show");
    assert_eq!(item.title, "Some Show");
    assert_eq!(item.cover_url.as_deref(), Some("https://img.test/a.jpg"));
    assert_eq!(item.latest_label.as_deref(), Some("Ep 20 / 26"));
}

#[test]
fn the_last_page_counts_the_current_page_marker() {
    let html = r#"<div id="animeList"><div class="product__item"><a href="/anime/1/a"><div class="product__item__pic"></div></a>
        <div class="product__item__text"><h5>A</h5></div></div></div>
        <div class="product__pagination"><a class="page__link">1</a><a class="page__link">8</a><a class="current-page">9</a></div>"#;
    assert_eq!(parse_listing_page(html, &base()).unwrap().total_pages, 9);
}

fn with_pagination(markup: &str) -> String {
    format!(
        r#"<div id="animeList"><div class="product__item"><a href="/anime/1/a"><div class="product__item__pic"></div></a>
        <div class="product__item__text"><h5>A</h5></div></div></div>
        <div class="product__pagination">{markup}</div>"#
    )
}

#[test]
fn a_middle_page_shows_no_last_number_but_its_next_arrow_still_proves_more_pages() {
    let html = with_pagination(
        r#"<a href="/properties/genre/x?page=1" class="page__link"><i class="fa fa-angle-left"></i></a>
        <a aria-disabled="true" class="gray__color"><label>...</label></a>
        <a class="current-page">2</a>
        <a aria-disabled="true" class="gray__color"><label>...</label></a>
        <a href="/properties/genre/x?order_by=ascending&amp;page=3" class="page__link"><i class="fa fa-angle-right"></i></a>"#,
    );
    assert_eq!(parse_listing_page(&html, &base()).unwrap().total_pages, 3);
}

#[test]
fn the_first_page_reads_the_last_number_and_the_arrow() {
    let html = with_pagination(
        r#"<a class="current-page">1</a>
        <a href="/properties/genre/x?page=6" class="page__link">6</a>
        <a href="/properties/genre/x?page=2" class="page__link"><i class="fa fa-angle-right"></i></a>"#,
    );
    assert_eq!(parse_listing_page(&html, &base()).unwrap().total_pages, 6);
}

#[test]
fn the_last_page_has_no_next_arrow_and_counts_itself() {
    let html = with_pagination(
        r#"<a href="/properties/genre/x?page=5" class="page__link"><i class="fa fa-angle-left"></i></a>
        <a href="/properties/genre/x?page=1" class="page__link">1</a>
        <a class="current-page">6</a>
        <a aria-disabled="true" class="gray__color"><i class="fa fa-angle-right"></i></a>"#,
    );
    assert_eq!(parse_listing_page(&html, &base()).unwrap().total_pages, 6);
}

#[test]
fn a_page_link_without_a_page_number_is_ignored() {
    let html = with_pagination(
        r#"<a href="/properties/genre/x" class="page__link">next</a><a class="current-page">1</a>"#,
    );
    assert_eq!(parse_listing_page(&html, &base()).unwrap().total_pages, 1);
}

#[test]
fn a_real_middle_genre_page_knows_that_more_pages_follow() {
    let html = fixtures::kuramanime("genre-page-middle.html");
    let page = parse_listing_page(&html, &live_base()).unwrap();
    assert!(page.items.len() >= 10);
    assert!(page.total_pages >= 3);
}

#[test]
fn parses_a_real_genre_page_like_any_other_listing() {
    let html = fixtures::kuramanime("genre-page.html");
    let page = parse_listing_page(&html, &live_base()).unwrap();
    assert!(page.items.len() >= 10);
    assert!(page.total_pages > 10);
}

#[test]
fn the_sites_own_empty_note_is_an_empty_list_not_changed_markup() {
    let html = fixtures::kuramanime("empty-search.html");
    let page = parse_listing_page(&html, &base()).unwrap();
    assert!(page.items.is_empty());
    assert_eq!(page.total_pages, 1);
}

#[test]
fn missing_markup_is_reported_explicitly() {
    let error = parse_listing_page("<main>changed</main>", &base())
        .err()
        .unwrap();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[test]
fn cards_with_no_usable_data_are_markup_changes_but_one_bad_card_is_skipped() {
    let broken = r#"<div id="animeList"><div class="filter__gallery"><a href="/nothing"><div class="product__sidebar__view__item"></div></a></div></div>"#;
    assert!(matches!(
        parse_listing_page(broken, &base()),
        Err(SourceError::MarkupChanged(_))
    ));
    let mixed = r#"<div id="animeList"><div class="filter__gallery">
        <a href="/anime/1/ok"><div class="product__sidebar__view__item"><h5 class="sidebar-title-h5">Ok</h5></div></a>
        <a href="/anime/2/untitled"><div class="product__sidebar__view__item"></div></a></div></div>"#;
    assert_eq!(parse_listing_page(mixed, &base()).unwrap().items.len(), 1);
}
