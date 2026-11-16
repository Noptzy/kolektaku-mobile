use domain::error::SourceError;
use domain::source::{ChapterText, TextBlock};
use scraper::Html;
use url::Url;

use super::pictures::page_picture;
use crate::sources::support::{collapse, selector, text_of};

const LANGUAGE: &str = "en";

pub fn parse_chapter_text(html: &str, base: &Url) -> Result<ChapterText, SourceError> {
    let document = Html::parse_document(html);
    let Some(content) = document.select(&selector(".mw-parser-output")).next() else {
        return Err(SourceError::MarkupChanged(
            "chapter text was not found".into(),
        ));
    };
    let headline = selector(".mw-headline");
    let mut blocks: Vec<TextBlock> = Vec::new();
    for element in content.select(&selector("p, h2, h3, img")) {
        match element.value().name() {
            "img" => {
                if let Some(url) = page_picture(element, base) {
                    blocks.push(TextBlock::Image(url));
                }
            }
            "p" => push_text(&mut blocks, collapse(&text_of(element))),
            _ => {
                let title = element
                    .select(&headline)
                    .next()
                    .map(|span| collapse(&text_of(span)))
                    .unwrap_or_default();
                push_text(&mut blocks, title);
            }
        }
    }
    if blocks.is_empty() {
        return Err(SourceError::MarkupChanged("chapter text is empty".into()));
    }
    Ok(ChapterText::new(LANGUAGE, blocks))
}

fn push_text(blocks: &mut Vec<TextBlock>, text: String) {
    if !text.is_empty() {
        blocks.push(TextBlock::Paragraph(text));
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    fn base() -> Url {
        Url::parse("https://www.baka-tsuki.org").unwrap()
    }

    #[test]
    fn a_chapter_is_its_heading_and_paragraphs_in_english() {
        let text = parse_chapter_text(&fixtures::read("bakatsuki", "chapter.html"), &base())
            .unwrap();
        assert_eq!(text.language, "en");
        let mut paragraphs = text.paragraphs();
        assert_eq!(paragraphs.next(), Some("1 - Letter from Banaras"));
        assert_eq!(paragraphs.next(), Some("Dear Houtarou,"));
        assert!(text.paragraphs().count() > 10);
        assert!(text.paragraphs().all(|paragraph| paragraph == paragraph.trim()));
    }

    #[test]
    fn the_licence_and_site_badges_are_not_pictures_of_the_story() {
        let text = parse_chapter_text(&fixtures::read("bakatsuki", "chapter.html"), &base())
            .unwrap();
        assert!(!text.blocks.iter().any(|block| matches!(block, TextBlock::Image(_))));
    }

    #[test]
    fn an_illustration_page_is_a_run_of_large_pictures() {
        let text =
            parse_chapter_text(&fixtures::read("bakatsuki", "illustrations.html"), &base())
                .unwrap();
        let pictures: Vec<&TextBlock> = text
            .blocks
            .iter()
            .filter(|block| matches!(block, TextBlock::Image(_)))
            .collect();
        assert!(pictures.len() >= 2);
        let TextBlock::Image(first) = pictures[0] else {
            panic!("expected a picture");
        };
        assert!(first.starts_with("https://www.baka-tsuki.org/project/thumb.php?f="));
        assert!(first.ends_with("width=1200"));
    }

    #[test]
    fn a_page_without_content_is_a_markup_change() {
        let result = parse_chapter_text("<main>redesigned</main>", &base());
        assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
        let empty = parse_chapter_text(r#"<div class="mw-parser-output"><p> </p></div>"#, &base());
        assert!(matches!(empty, Err(SourceError::MarkupChanged(_))));
    }
}
