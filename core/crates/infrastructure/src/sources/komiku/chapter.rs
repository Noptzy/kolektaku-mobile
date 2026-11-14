use domain::error::SourceError;
use domain::source::ChapterPages;
use scraper::Html;
use url::Url;

use crate::sources::support::{absolute_url, selector};

const PROMOTION_MARKERS: [&str; 3] = ["promosi", "banner", "logo"];

fn is_promotion(url: &str) -> bool {
    let lower = url.to_lowercase();
    PROMOTION_MARKERS
        .iter()
        .any(|marker| lower.contains(marker))
}

pub fn parse_chapter_pages(html: &str, base: &Url) -> Result<ChapterPages, SourceError> {
    let document = Html::parse_document(html);
    let mut urls: Vec<String> = Vec::new();
    for image in document.select(&selector("#Baca_Komik img")) {
        let value = image.value();
        let source = value
            .attr("src")
            .or(value.attr("data-src"))
            .unwrap_or_default();
        if let Some(url) = absolute_url(source, base).filter(|url| !is_promotion(url))
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    fn site() -> Url {
        Url::parse("https://komiku.org").unwrap()
    }

    #[test]
    fn returns_the_pages_in_order_and_skips_the_site_banner() {
        let chapter = parse_chapter_pages(&fixtures::komiku("chapter.html"), &site()).unwrap();
        assert!(chapter.pages.len() > 20);
        assert!(
            chapter
                .pages
                .iter()
                .all(|page| !page.url.to_lowercase().contains("promosi"))
        );
        assert!(chapter.pages[0].url.ends_with("-1.jpg"));
        assert!(
            chapter
                .pages
                .iter()
                .all(|page| page.url.starts_with("https://"))
        );
    }

    #[test]
    fn repeated_images_appear_once_and_lazy_sources_are_read() {
        let html = r#"<div id="Baca_Komik"><img src="/a.jpg"><img data-src="/b.jpg"><img src="/a.jpg"><img src="/logo.png"></div>"#;
        let urls: Vec<String> = parse_chapter_pages(html, &site())
            .unwrap()
            .pages
            .into_iter()
            .map(|page| page.url)
            .collect();
        assert_eq!(
            urls,
            vec!["https://komiku.org/a.jpg", "https://komiku.org/b.jpg"]
        );
    }

    #[test]
    fn a_reader_without_images_is_a_markup_change() {
        let result = parse_chapter_pages(r#"<div id="Baca_Komik"></div>"#, &site());
        assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
    }
}
