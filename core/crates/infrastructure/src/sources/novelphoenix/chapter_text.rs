use domain::error::SourceError;
use domain::source::ChapterText;
use scraper::Html;

use crate::sources::support::{collapse, selector, text_of};

const LANGUAGE: &str = "en";

pub fn parse_chapter_text(html: &str) -> Result<ChapterText, SourceError> {
    let document = Html::parse_document(html);
    let Some(content) = document.select(&selector("#content")).next() else {
        return Err(SourceError::MarkupChanged(
            "chapter text was not found".into(),
        ));
    };
    let paragraphs: Vec<String> = content
        .select(&selector("p"))
        .map(|paragraph| collapse(&text_of(paragraph)))
        .filter(|text| !text.is_empty())
        .collect();
    if paragraphs.is_empty() {
        return Err(SourceError::MarkupChanged("chapter text is empty".into()));
    }
    Ok(ChapterText::from_paragraphs(LANGUAGE, paragraphs))
}
