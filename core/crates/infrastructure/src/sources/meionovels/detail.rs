use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem};
use scraper::Html;
use url::Url;

use super::title::{clean_title, is_adult_genre};
use crate::sources::support::{absolute_url, collapse, known_text, selector, text_of};

fn info_rows(document: &Html) -> HashMap<String, String> {
    let mut rows = HashMap::new();
    for item in document.select(&selector(".post-content_item")) {
        let heading = item
            .select(&selector(".summary-heading"))
            .next()
            .map(|node| collapse(&text_of(node)).to_lowercase());
        let value = item
            .select(&selector(".summary-content"))
            .next()
            .map(|node| collapse(&text_of(node)));
        if let (Some(heading), Some(value)) = (heading, value) {
            rows.insert(heading, value);
        }
    }
    rows
}

fn synopsis_of(document: &Html) -> String {
    document
        .select(&selector(".description-summary .summary__content p"))
        .map(|paragraph| collapse(&text_of(paragraph)))
        .filter(|text| !text.is_empty())
        .collect::<Vec<_>>()
        .join("\n\n")
}

fn year_of(rows: &HashMap<String, String>) -> Option<u16> {
    rows.get("release")?
        .split(|c: char| !c.is_ascii_digit())
        .find(|part| part.len() == 4)
        .and_then(|part| part.parse().ok())
}

fn chapter_count(rows: &HashMap<String, String>) -> Option<u32> {
    rows.get("chapters")?
        .split(|c: char| !c.is_ascii_digit())
        .find(|part| !part.is_empty())
        .and_then(|part| part.parse().ok())
}

fn alternative_titles(rows: &HashMap<String, String>, title: &str) -> Vec<String> {
    let Some(text) = rows.get("alternative") else {
        return Vec::new();
    };
    text.split(';')
        .map(clean_title)
        .filter(|part| !part.is_empty() && part != "-" && part != title)
        .collect()
}

pub fn parse_detail(html: &str, slug: &str, base: &Url) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let heading = document
        .select(&selector(".post-title h1"))
        .next()
        .map(|node| collapse(&text_of(node)))
        .filter(|text| !text.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("detail title was not found".into()))?;
    let title = clean_title(&heading);
    let genres: Vec<String> = document
        .select(&selector(".genres-content a"))
        .map(|anchor| collapse(&text_of(anchor)))
        .filter(|genre| !genre.is_empty())
        .collect();
    if genres.iter().any(|genre| is_adult_genre(genre)) {
        return Err(SourceError::NotFound(slug.to_string()));
    }
    let rows = info_rows(&document);
    let cover = document
        .select(&selector(".summary_image img"))
        .next()
        .and_then(|image| image.value().attr("src"))
        .and_then(|source| absolute_url(source, base));
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(slug),
            title: title.clone(),
            cover_url: cover,
            latest_label: None,
        },
        alternative_titles: alternative_titles(&rows, &title),
        type_text: rows.get("type").and_then(|text| known_text(text)),
        year: year_of(&rows),
        unit_count: chapter_count(&rows),
        origin: None,
        synopsis: synopsis_of(&document),
        genres,
    })
}
