use domain::error::SourceError;
use url::Url;

use super::detail::{parse_chapter_list, parse_detail};
use crate::fixtures;

fn site() -> Url {
    Url::parse("https://komiku.org").unwrap()
}

#[test]
fn reads_the_info_table_alternative_titles_synopsis_and_chapter_count() {
    let html = fixtures::komiku("detail.html");
    let detail = parse_detail(&html, "123213-chainsaw-man", &site()).unwrap();
    assert_eq!(detail.item.item_id.as_str(), "123213-chainsaw-man");
    assert_eq!(detail.item.title, "Chainsaw Man");
    assert_eq!(detail.type_text.as_deref(), Some("Manga"));
    assert_eq!(detail.alternative_titles, vec!["Manusia Gergaji Mesin"]);
    for genre in ["Action", "Comedy", "Horror"] {
        assert!(detail.genres.iter().any(|known| known == genre), "{genre}");
    }
    assert!(detail.synopsis.contains("Denji"));
    assert!(
        detail
            .item
            .cover_url
            .as_deref()
            .unwrap()
            .starts_with("https:")
    );
    assert_eq!(detail.unit_count, Some(39));
    assert!(detail.item.latest_label.is_some());
}

#[test]
fn lists_chapters_lowest_first_with_decimals_and_without_duplicates() {
    let html = r#"<table id="Daftar_Chapter">
      <tr><td class="judulseries"><a href="/x-chapter-11/"><b>Chapter 11</b></a></td></tr>
      <tr><td class="judulseries"><a href="/x-chapter-10-5/"><b>Chapter 10.5</b></a></td></tr>
      <tr><td class="judulseries"><a href="/x-chapter-10/"><b>Chapter 10</b></a></td></tr>
      <tr><td class="judulseries"><a href="/x-chapter-10/"><b>Chapter 10</b></a></td></tr>
      <tr><td class="judulseries"><a href="/x-extra/"><b>Extra</b></a></td></tr>
    </table>"#;
    let chapters: Vec<(String, f64)> = parse_chapter_list(html)
        .into_iter()
        .map(|chapter| (chapter.id, chapter.number))
        .collect();
    assert_eq!(
        chapters,
        vec![
            ("x-chapter-10".to_string(), 10.0),
            ("x-chapter-10-5".to_string(), 10.5),
            ("x-chapter-11".to_string(), 11.0),
        ]
    );
}

#[test]
fn chapter_links_may_be_absolute() {
    let html = r#"<table id="Daftar_Chapter"><tr><td class="judulseries"><a href="https://komiku.org/y-chapter-1/"><b>Chapter 1</b></a></td></tr></table>"#;
    assert_eq!(parse_chapter_list(html)[0].id, "y-chapter-1");
}

#[test]
fn the_title_falls_back_to_the_heading_without_its_komik_prefix() {
    let html = r#"<h1>Komik Berserk</h1>"#;
    let detail = parse_detail(html, "berserk", &site()).unwrap();
    assert_eq!(detail.item.title, "Berserk");
    assert_eq!(detail.unit_count, None);
}

#[test]
fn a_page_without_a_title_is_a_markup_change() {
    let error = parse_detail("<main></main>", "x", &site()).unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}
