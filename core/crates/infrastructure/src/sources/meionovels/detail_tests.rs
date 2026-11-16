use domain::error::SourceError;
use url::Url;

use super::detail::parse_detail;
use crate::fixtures;

fn site() -> Url {
    Url::parse("https://meionovels.com").unwrap()
}

fn detail() -> domain::source::SourceDetail {
    parse_detail(
        &fixtures::meionovels("detail.html"),
        "mushoku-tensei-ln",
        &site(),
    )
    .unwrap()
}

#[test]
fn the_title_is_cleaned_and_the_cover_is_read() {
    let detail = detail();
    assert_eq!(detail.item.item_id.as_str(), "mushoku-tensei-ln");
    assert_eq!(detail.item.title, "Mushoku Tensei");
    assert!(detail.item.cover_url.as_deref().unwrap().ends_with(".jpg"));
}

#[test]
fn the_facts_come_from_the_info_rows() {
    let detail = detail();
    assert_eq!(detail.type_text.as_deref(), Some("Light Novel Jepang"));
    assert_eq!(detail.year, Some(2014));
    assert_eq!(detail.unit_count, Some(450));
    assert_eq!(
        detail.alternative_titles,
        vec!["Jobless Reincarnation ~ It will be All Out if I Go to Another World ~"]
    );
}

#[test]
fn genres_are_listed_and_the_mild_mature_label_does_not_hide_a_title() {
    let detail = detail();
    assert!(detail.genres.contains(&"Fantasy".to_string()));
    assert!(detail.genres.contains(&"Mature".to_string()));
    assert_eq!(detail.genres.len(), 11);
}

#[test]
fn the_synopsis_keeps_its_paragraphs() {
    let detail = detail();
    assert!(detail.synopsis.starts_with("Seorang otaku NEET"));
    assert_eq!(detail.synopsis.matches("\n\n").count(), 2);
}

#[test]
fn a_page_without_a_title_is_a_markup_change() {
    let result = parse_detail("<main>redesigned</main>", "x", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[test]
fn a_title_of_an_adult_genre_is_not_found() {
    let html = r#"<div class="post-title"><h1>Judul</h1></div><div class="genres-content"><a>Romance</a>, <a>Smut</a></div>"#;
    let result = parse_detail(html, "judul", &site());
    assert!(matches!(result, Err(SourceError::NotFound(_))));
}

#[test]
fn missing_facts_stay_unknown() {
    let html = r#"<div class="post-title"><h1>Judul LN</h1></div>"#;
    let detail = parse_detail(html, "judul-ln", &site()).unwrap();
    assert_eq!(detail.item.title, "Judul");
    assert_eq!(detail.type_text, None);
    assert_eq!(detail.year, None);
    assert_eq!(detail.unit_count, None);
    assert!(detail.alternative_titles.is_empty() && detail.genres.is_empty());
}
