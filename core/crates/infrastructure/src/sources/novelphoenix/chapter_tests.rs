use domain::error::SourceError;
use domain::source::TextBlock;
use url::Url;

use super::chapter_text::parse_chapter_text;
use super::chapters::{page_count, parse_chapter_pages};
use crate::fixtures;

const SLUG: &str = "the-beginning-after-the-end";

fn page() -> String {
    fixtures::novelphoenix("chapters.html")
}

fn site() -> Url {
    Url::parse("https://novelphoenix.com").unwrap()
}

#[test]
fn the_last_page_number_is_read_from_the_pagination() {
    assert_eq!(page_count(&page()), 6);
    assert_eq!(page_count("<main>one page</main>"), 1);
}

#[test]
fn a_page_lists_chapters_in_reading_order_with_running_numbers() {
    let units = parse_chapter_pages(&[page()], SLUG);
    assert_eq!(units.len(), 40);
    assert_eq!(units[0].number, 1.0);
    assert_eq!(units[0].id, "the-beginning-after-the-end/chapter-1");
    assert_eq!(units[0].label, "Ch. 1 \u{b7} c-1: Prologue: Start");
    assert_eq!(units[39].number, 40.0);
}

#[test]
fn pages_are_joined_in_the_order_given_and_repeats_are_dropped() {
    let one = r#"<ul class="chapter-list"><li><a href="/novel/x/chapter-1"><span class="chapter-no">Ch. 1</span><strong class="chapter-title">A</strong></a></li><li><a href="/novel/x/chapter-2"><span class="chapter-no">Ch. 2</span></a></li></ul>"#;
    let two = r#"<ul class="chapter-list"><li><a href="/novel/x/chapter-2"><span class="chapter-no">Ch. 2</span></a></li><li><a href="/novel/x/chapter-3"><strong class="chapter-title">C</strong></a></li><li><a href="/novel/other/chapter-9">Elsewhere</a></li></ul>"#;
    let units = parse_chapter_pages(&[one.to_string(), two.to_string()], "x");
    let labels: Vec<&str> = units.iter().map(|unit| unit.label.as_str()).collect();
    assert_eq!(labels, vec!["Ch. 1 \u{b7} A", "Ch. 2", "C"]);
    assert_eq!(units[2].number, 3.0);
}

#[test]
fn the_link_to_the_latest_chapter_outside_the_list_is_not_counted() {
    let html = r#"<p>Latest: <a href="/novel/x/chapter-99">Chapter 99</a></p><ul class="chapter-list"><li><a href="/novel/x/chapter-1">Ch. 1</a></li></ul>"#;
    assert_eq!(parse_chapter_pages(&[html.to_string()], "x").len(), 1);
}

#[test]
fn the_text_is_the_paragraphs_of_the_content_area_in_english() {
    let text = parse_chapter_text(&fixtures::novelphoenix("chapter.html"), &site()).unwrap();
    assert_eq!(text.language, "en");
    let first = text.paragraphs().next().unwrap();
    assert!(first.contains("The Continent of Dicathen comprises"));
    assert_eq!(text.paragraphs().count(), 16);
    assert!(text.paragraphs().all(|paragraph| paragraph == paragraph.trim()));
}

#[test]
fn a_page_without_text_is_a_markup_change() {
    for html in ["<main>redesigned</main>", r#"<div id="content"><p> </p></div>"#] {
        assert!(matches!(
            parse_chapter_text(html, &site()),
            Err(SourceError::MarkupChanged(_))
        ));
    }
}

#[test]
fn illustrations_keep_their_place_between_paragraphs_even_when_lazy_loaded() {
    let html = r#"<div id="content"><p>Satu.</p>
        <img class="lazy" src="data:image/gif;base64,R0lGOD" data-src="/img/ilustrasi-1.jpg">
        <p>Dua.</p><p><img src="https://cdn.test/dua.png"></p><p>Tiga.</p></div>"#;
    let text = parse_chapter_text(html, &site()).unwrap();
    assert_eq!(
        text.blocks,
        vec![
            TextBlock::Paragraph("Satu.".into()),
            TextBlock::Image("https://novelphoenix.com/img/ilustrasi-1.jpg".into()),
            TextBlock::Paragraph("Dua.".into()),
            TextBlock::Image("https://cdn.test/dua.png".into()),
            TextBlock::Paragraph("Tiga.".into()),
        ]
    );
}

#[test]
fn a_chapter_with_only_an_illustration_is_still_a_chapter() {
    let html = r#"<div id="content"><img data-src="/a.jpg" src=""></div>"#;
    let text = parse_chapter_text(html, &site()).unwrap();
    assert_eq!(text.blocks.len(), 1);
}
