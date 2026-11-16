use domain::error::SourceError;
use domain::source::{ChapterText, TextBlock};
use scraper::Html;
use url::Url;

use crate::sources::support::{collapse, image_of, selector, text_of};

const LANGUAGE: &str = "en";

pub fn parse_chapter_text(html: &str, base: &Url) -> Result<ChapterText, SourceError> {
    let document = Html::parse_document(html);
    let Some(content) = document.select(&selector("#content")).next() else {
        return Err(SourceError::MarkupChanged(
            "chapter text was not found".into(),
        ));
    };
    let mut blocks: Vec<TextBlock> = Vec::new();
    for element in content.select(&selector("p, img")) {
        if element.value().name() == "img" {
            if let Some(url) = image_of(element, base) {
                blocks.push(TextBlock::Image(url));
            }
            continue;
        }
        let text = collapse(&text_of(element));
        if !text.is_empty() {
            blocks.push(TextBlock::Paragraph(text));
        }
    }
    if blocks.is_empty() {
        return Err(SourceError::MarkupChanged("chapter text is empty".into()));
    }
    Ok(ChapterText::new(LANGUAGE, blocks))
}
