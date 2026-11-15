use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem};
use scraper::Html;
use url::Url;

use crate::sources::support::{absolute_url, collapse, is_adult_genre, selector, text_of};

const TYPE_TEXT: &str = "Web Novel";

fn chapter_count(document: &Html) -> Option<u32> {
    let stat = document
        .select(&selector(".header-stats span strong"))
        .next()?;
    let digits: String = text_of(stat).chars().filter(char::is_ascii_digit).collect();
    digits.parse().ok()
}

fn synopsis_of(document: &Html) -> String {
    document
        .select(&selector(".summary .content p"))
        .map(|paragraph| collapse(&text_of(paragraph)))
        .filter(|text| !text.is_empty())
        .collect::<Vec<_>>()
        .join("\n\n")
}

pub fn parse_detail(html: &str, slug: &str, base: &Url) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let title = document
        .select(&selector("h1.novel-title"))
        .next()
        .map(|node| collapse(&text_of(node)))
        .filter(|text| !text.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("detail title was not found".into()))?;
    let genres: Vec<String> = document
        .select(&selector(".categories ul li a"))
        .map(|anchor| collapse(&text_of(anchor)))
        .filter(|genre| !genre.is_empty())
        .collect();
    if genres.iter().any(|genre| is_adult_genre(genre)) {
        return Err(SourceError::NotFound(slug.to_string()));
    }
    let cover = document
        .select(&selector(".fixed-img img"))
        .next()
        .and_then(|image| image.value().attr("src"))
        .and_then(|source| absolute_url(source, base));
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(slug),
            title,
            cover_url: cover,
            latest_label: None,
        },
        alternative_titles: Vec::new(),
        type_text: Some(TYPE_TEXT.into()),
        year: None,
        unit_count: chapter_count(&document),
        origin: None,
        synopsis: synopsis_of(&document),
        genres,
    })
}
