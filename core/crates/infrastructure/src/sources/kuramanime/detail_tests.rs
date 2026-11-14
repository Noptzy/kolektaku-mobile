use domain::error::SourceError;
use url::Url;

use super::detail::{find_year, looks_like_a_detail_page, parse_detail};
use crate::fixtures;

fn live_base() -> Url {
    Url::parse("https://v20.kuramanime.ing").unwrap()
}

#[test]
fn reads_type_year_count_genres_and_alternative_titles_from_the_real_page() {
    let html = fixtures::kuramanime("detail-live.html");
    let detail = parse_detail(&html, "50/one-piece", &live_base()).unwrap();
    assert_eq!(detail.item.item_id.as_str(), "50/one-piece");
    assert_eq!(detail.item.title, "One Piece");
    assert_eq!(detail.type_text.as_deref(), Some("TV"));
    assert_eq!(detail.year, Some(1999));
    assert_eq!(detail.unit_count, None);
    assert_eq!(detail.genres, vec!["Action", "Adventure", "Fantasy"]);
    assert!(detail.alternative_titles.contains(&"ONE PIECE".to_string()));
    assert!(detail.alternative_titles.contains(&"OP".to_string()));
    assert!(detail.synopsis.contains("Gol D. Roger"));
    assert!(
        detail
            .item
            .cover_url
            .as_deref()
            .unwrap()
            .starts_with("https:")
    );
    assert_eq!(detail.origin.as_deref(), Some("JP"));
    assert!(detail.item.latest_label.is_some());
}

#[test]
fn reads_a_known_episode_count_and_a_movie_type() {
    let html = r#"<div class="anime__details__title"><h3>Spy x Family Code: White</h3></div>
      <div class="anime__details__widget"><ul>
        <li><span class="col-3"><span>Tipe:</span></span><span class="col-9">Movie</span></li>
        <li><span class="col-3"><span>Episode:</span></span><span class="col-9">1</span></li>
        <li><span class="col-3"><span>Tayang:</span></span><span class="col-9">22 Des 2023 s/d 22 Des 2023</span></li>
      </ul></div>"#;
    let detail = parse_detail(html, "9/spy", &live_base()).unwrap();
    assert_eq!(detail.type_text.as_deref(), Some("Movie"));
    assert_eq!(detail.unit_count, Some(1));
    assert_eq!(detail.year, Some(2023));
}

#[test]
fn reads_the_country_in_upper_case() {
    let html = r#"<div class="anime__details__title"><h3>X</h3></div><div class="anime__details__widget"><ul><li><span class="col-3"><span>Negara:</span></span><span class="col-9">cn</span></li></ul></div>"#;
    let detail = parse_detail(html, "1/x", &live_base()).unwrap();
    assert_eq!(detail.origin.as_deref(), Some("CN"));
}

#[test]
fn the_small_fixture_has_genres_cover_and_the_latest_episode() {
    let html = fixtures::kuramanime("detail-small.html");
    let detail = parse_detail(&html, "50/one-piece", &live_base()).unwrap();
    assert_eq!(detail.genres, vec!["Action", "Adventure"]);
    assert_eq!(
        detail.item.cover_url.as_deref(),
        Some("https://img.example/one-piece.jpg")
    );
    assert_eq!(detail.item.latest_label.as_deref(), Some("Episode 1145"));
    assert_eq!(detail.alternative_titles, vec!["ワンピース"]);
}

#[test]
fn a_page_without_a_title_is_a_markup_change() {
    let error = parse_detail("<main></main>", "50/one-piece", &live_base()).unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[test]
fn years_are_taken_from_whole_words_only() {
    assert_eq!(find_year("Okt 2019 s/d ?"), Some(2019));
    assert_eq!(find_year("x1999 y"), None);
    assert_eq!(find_year("12345"), None);
    assert_eq!(find_year("3000 1850"), None);
}

#[test]
fn a_detail_page_is_recognized_by_its_title_even_without_episodes() {
    let aired_nothing_yet = r#"<div class="anime__details__title"><h3>Upcoming</h3></div>"#;
    assert!(looks_like_a_detail_page(aired_nothing_yet));
    assert!(!looks_like_a_detail_page("<main>redesigned</main>"));
}
