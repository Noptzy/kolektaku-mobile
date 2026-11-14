use domain::error::SourceError;
use domain::source::ChapterPages;
use scraper::Html;
use url::Url;

use crate::sources::support::{absolute_url, selector};

pub fn parse_chapter_pages(html: &str, base: &Url) -> Result<ChapterPages, SourceError> {
    let document = Html::parse_document(html);
    let mut urls: Vec<String> = Vec::new();
    for image in document.select(&selector("#Baca_Komik .img-landmine img")) {
        let value = image.value();
        let source = value
            .attr("src")
            .or(value.attr("data-src"))
            .unwrap_or_default();
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::fixtures;

    fn base() -> Url {
        Url::parse("https://komikindo.example").unwrap()
    }

    #[test]
    fn reads_the_images_in_order() {
        let chapter = parse_chapter_pages(&fixtures::komikindo("chapter.html"), &base()).unwrap();
        let urls: Vec<&str> = chapter.pages.iter().map(|page| page.url.as_str()).collect();
        assert_eq!(
            urls,
            vec![
                "https://komikindo.example/img/1.jpg",
                "https://komikindo.example/img/2.jpg",
                "https://komikindo.example/img/3.jpg",
            ]
        );
    }

    #[test]
    fn lazy_sources_are_read_and_repeats_dropped() {
        let html = r#"<div id="Baca_Komik"><div class="img-landmine"><img data-src="/a.jpg"><img src="/a.jpg"><img src="/b.jpg"></div></div>"#;
        assert_eq!(parse_chapter_pages(html, &base()).unwrap().pages.len(), 2);
    }

    #[test]
    fn a_reader_without_images_is_a_markup_change() {
        let result = parse_chapter_pages("<div id='Baca_Komik'></div>", &base());
        assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
    }
}
