use domain::error::SourceError;
use url::Url;

use super::detail::{parse_chapter_list, parse_detail};
use crate::fixtures;

fn base() -> Url {
    Url::parse("https://komikindo.example").unwrap()
}

#[test]
fn reads_the_detail_and_the_chapters_lowest_first_decimals_included() {
    let html = fixtures::komikindo("detail.html");
    let detail = parse_detail(&html, "chainsaw-man", &base()).unwrap();
    assert_eq!(detail.item.title, "Chainsaw Man");
    assert_eq!(detail.alternative_titles, vec!["チェンソーマン"]);
    assert_eq!(detail.genres, vec!["Action", "Comedy", "Horror"]);
    assert_eq!(detail.unit_count, Some(4));
    assert_eq!(detail.item.latest_label.as_deref(), Some("Chapter 3"));
    assert!(detail.synopsis.contains("Denji"));
    assert_eq!(
        detail.item.cover_url.as_deref(),
        Some("https://komikindo.example/wp-content/uploads/chainsaw-man.jpg")
    );
    let chapters: Vec<(String, f64)> = parse_chapter_list(&html)
        .into_iter()
        .map(|chapter| (chapter.id, chapter.number))
        .collect();
    assert_eq!(
        chapters,
        vec![
            ("chainsaw-man-chapter-1".to_string(), 1.0),
            ("chainsaw-man-chapter-2".to_string(), 2.0),
            ("chainsaw-man-chapter-2-5".to_string(), 2.5),
            ("chainsaw-man-chapter-3".to_string(), 3.0),
        ]
    );
}

#[test]
fn the_type_comes_from_the_info_line_or_else_the_type_flag() {
    let with_info = r#"<h1 class="entry-title">Komik X</h1><div class="infox"><span><b>Jenis Komik:</b> Manhwa</span></div>"#;
    assert_eq!(
        parse_detail(with_info, "x", &base())
            .unwrap()
            .type_text
            .as_deref(),
        Some("Manhwa")
    );
    let with_flag = r#"<h1 class="entry-title">Komik X</h1><div class="infox"><span class="typeflag Manhua"></span></div>"#;
    assert_eq!(
        parse_detail(with_flag, "x", &base())
            .unwrap()
            .type_text
            .as_deref(),
        Some("Manhua")
    );
    let neither = r#"<h1 class="entry-title">Komik X</h1>"#;
    assert_eq!(parse_detail(neither, "x", &base()).unwrap().type_text, None);
}

#[test]
fn chapters_without_a_number_are_skipped_and_plain_labels_are_kept() {
    let html = r#"<div id="chapter_list"><ul>
        <li><a href="/a-1/"><chapter>Chapter 1</chapter></a></li>
        <li><a href="/a-extra/"><chapter>Extra</chapter></a></li>
        <li><a href="/a-2/">Ch. 2</a></li></ul></div>"#;
    let chapters = parse_chapter_list(html);
    let labels: Vec<&str> = chapters
        .iter()
        .map(|chapter| chapter.label.as_str())
        .collect();
    assert_eq!(labels, vec!["Chapter 1", "Ch. 2"]);
}

#[test]
fn a_page_without_a_title_is_a_markup_change() {
    let error = parse_detail("<main></main>", "x", &base()).unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}
