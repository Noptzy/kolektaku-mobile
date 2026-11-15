use domain::error::SourceError;
use domain::source::{ChapterText, TextBlock};
use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{absolute_url, collapse, selector};

const LANGUAGE: &str = "id";

fn text_with_breaks(element: ElementRef) -> String {
    let mut text = String::new();
    for node in element.descendants() {
        if let Some(piece) = node.value().as_text() {
            text.push_str(piece);
        } else if node.value().as_element().is_some_and(|inner| inner.name() == "br") {
            text.push(' ');
        }
    }
    text
}

fn push_text(blocks: &mut Vec<TextBlock>, element: ElementRef) {
    let text = collapse(&text_with_breaks(element));
    if !text.is_empty() {
        blocks.push(TextBlock::Paragraph(text));
    }
}

fn push_images(blocks: &mut Vec<TextBlock>, element: ElementRef, base: &Url) {
    for image in element.select(&selector("img")) {
        let value = image.value();
        let source = value.attr("src").or(value.attr("data-src"));
        if let Some(url) = source.and_then(|source| absolute_url(source, base)) {
            blocks.push(TextBlock::Image(url));
        }
    }
}

fn read_children(container: ElementRef, base: &Url) -> Vec<TextBlock> {
    let mut blocks = Vec::new();
    for child in container.children().filter_map(ElementRef::wrap) {
        match child.value().name() {
            "script" | "style" | "ins" | "iframe" => {}
            "p" | "h1" | "h2" | "h3" | "h4" | "blockquote" => {
                let before = blocks.len();
                push_images(&mut blocks, child, base);
                if blocks.len() == before {
                    push_text(&mut blocks, child);
                }
            }
            "img" | "figure" | "div" => push_images(&mut blocks, child, base),
            _ => push_text(&mut blocks, child),
        }
    }
    blocks
}

pub fn parse_chapter_text(html: &str, base: &Url) -> Result<ChapterText, SourceError> {
    let document = Html::parse_document(html);
    let Some(container) = document.select(&selector(".reading-content .text-left")).next() else {
        return Err(SourceError::MarkupChanged(
            "chapter text was not found".into(),
        ));
    };
    let blocks = read_children(container, base);
    if blocks.is_empty() {
        return Err(SourceError::MarkupChanged("chapter text is empty".into()));
    }
    Ok(ChapterText::new(LANGUAGE, blocks))
}
