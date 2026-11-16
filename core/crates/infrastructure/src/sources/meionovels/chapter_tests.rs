use domain::error::SourceError;
use domain::source::TextBlock;
use url::Url;

use super::chapter_text::parse_chapter_text;
use super::chapters::parse_chapter_list;
use crate::fixtures;

const SLUG: &str = "mushoku-tensei-ln";

fn site() -> Url {
    Url::parse("https://meionovels.com").unwrap()
}

#[test]
fn the_list_is_read_from_the_first_chapter_with_running_numbers() {
    let units = parse_chapter_list(&fixtures::meionovels("ajax-chapters.html"), SLUG);
    assert_eq!(units.len(), 60);
    assert_eq!(units[0].number, 1.0);
    assert_eq!(units[0].label, "Volume 1 Chapter 0 - Prolog");
    assert_eq!(units[0].id, "mushoku-tensei-ln/volume-1-chapter-0");
    let last = units.last().unwrap();
    assert_eq!(last.number, 60.0);
    assert_eq!(last.label, "Volume Redundant Reincarnation 3 Chapter 10");
}

#[test]
fn numbers_are_one_step_apart_and_ids_are_unique() {
    let units = parse_chapter_list(&fixtures::meionovels("ajax-chapters.html"), SLUG);
    assert!(
        units
            .windows(2)
            .all(|pair| (pair[1].number - pair[0].number - 1.0).abs() < f64::EPSILON)
    );
    let mut ids: Vec<&str> = units.iter().map(|unit| unit.id.as_str()).collect();
    ids.sort_unstable();
    ids.dedup();
    assert_eq!(ids.len(), units.len());
}

#[test]
fn a_chapter_listed_twice_is_kept_once_and_foreign_links_are_ignored() {
    let html = r#"<ul class="main"><li class="wp-manga-chapter"><a href="https://s.test/novel/x/b-2/">B 2</a></li>
        <li class="wp-manga-chapter"><a href="https://s.test/novel/x/b-2/">B 2 again</a></li>
        <li class="wp-manga-chapter"><a href="https://s.test/novel/other/b-1/">Elsewhere</a></li>
        <li class="wp-manga-chapter"><a href="https://s.test/novel/x/b-1/">B 1</a></li></ul>"#;
    let units = parse_chapter_list(html, "x");
    let labels: Vec<&str> = units.iter().map(|unit| unit.label.as_str()).collect();
    assert_eq!(labels, vec!["B 1", "B 2"]);
}

#[test]
fn a_page_without_chapters_gives_an_empty_list() {
    assert!(parse_chapter_list("<main>redesigned</main>", SLUG).is_empty());
}

#[test]
fn the_text_is_paragraphs_in_order_without_blank_lines() {
    let text = parse_chapter_text(&fixtures::meionovels("chapter.html"), &site()).unwrap();
    assert_eq!(text.language, "id");
    let first = text.paragraphs().next().unwrap();
    assert_eq!(first, "Bab 1: Apakah Ini Dunia Lain?");
    assert!(text.paragraphs().all(|paragraph| !paragraph.trim().is_empty()));
    assert!(text.paragraphs().count() > 60);
}

#[test]
fn no_break_spaces_become_ordinary_spaces() {
    let text = parse_chapter_text(&fixtures::meionovels("chapter.html"), &site()).unwrap();
    assert!(text.paragraphs().any(|paragraph| paragraph == "Siapa yang dia? Saya pikir."));
    assert!(text.paragraphs().all(|paragraph| !paragraph.contains('\u{a0}')));
}

#[test]
fn illustrations_keep_their_place_between_paragraphs() {
    let text =
        parse_chapter_text(&fixtures::meionovels("chapter-illustrated.html"), &site()).unwrap();
    let images: Vec<usize> = text
        .blocks
        .iter()
        .enumerate()
        .filter(|(_, block)| matches!(block, TextBlock::Image(_)))
        .map(|(index, _)| index)
        .collect();
    assert!(images.len() >= 3);
    for block in &text.blocks {
        if let TextBlock::Image(url) = block {
            assert!(url.starts_with("https://"));
        }
    }
    assert!(text.paragraphs().count() > 5);
}

#[test]
fn ads_and_scripts_inside_the_text_are_left_out() {
    let html = r#"<div class="reading-content"><div class="text-left"><p>Satu</p><script>track()</script><ins class="adsbygoogle">iklan</ins><div class="ads"><a href="/x">pasang</a></div><p>Dua</p></div></div>"#;
    let text = parse_chapter_text(html, &site()).unwrap();
    let all: Vec<&str> = text.paragraphs().collect();
    assert_eq!(all, vec!["Satu", "Dua"]);
    assert_eq!(text.blocks.len(), 2);
}

#[test]
fn a_page_without_the_reading_area_is_a_markup_change() {
    let result = parse_chapter_text("<main>redesigned</main>", &site());
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
    let empty = parse_chapter_text(
        r#"<div class="reading-content"><div class="text-left"><p>&nbsp;</p></div></div>"#,
        &site(),
    );
    assert!(matches!(empty, Err(SourceError::MarkupChanged(_))));
}
