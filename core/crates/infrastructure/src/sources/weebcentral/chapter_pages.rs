use domain::error::SourceError;
use domain::source::ChapterPages;
use scraper::Html;
use url::Url;

use crate::sources::support::{absolute_url, selector};

pub fn parse_chapter_pages(html: &str, base: &Url) -> Result<ChapterPages, SourceError> {
    let document = Html::parse_document(html);
    let mut urls: Vec<String> = Vec::new();
    for image in document.select(&selector("img")) {
        let source = image.value().attr("src").unwrap_or_default();
        if source.contains("/static/") {
            continue;
        }
        if let Some(url) = absolute_url(source, base)
            && !urls.contains(&url)
        {
            urls.push(url);
        }
    }
    if urls.is_empty() {
        return Err(SourceError::MarkupChanged(
            "chapter images were not found".into(),
        ));
    }
    Ok(ChapterPages::from_urls(urls))
}
