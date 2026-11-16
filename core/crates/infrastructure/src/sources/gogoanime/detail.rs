use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem};
use scraper::Html;

use super::episodes::parse_units;
use super::urls::GogoanimeUrls;
use crate::sources::support::{
    absolute_url, collapse, first_number, known_text, selector, text_of,
};

fn read_info(document: &Html) -> HashMap<String, String> {
    let mut info = HashMap::new();
    for row in document.select(&selector(".info-content .spe > span")) {
        let Some(label) = row.select(&selector("b")).next() else {
            continue;
        };
        let key = collapse(&text_of(label)).trim_end_matches(':').to_lowercase();
        let whole = collapse(&text_of(row));
        let value = whole
            .strip_prefix(collapse(&text_of(label)).as_str())
            .map(|rest| rest.trim().to_string())
            .unwrap_or_default();
        if !key.is_empty() && !value.is_empty() {
            info.entry(key).or_insert(value);
        }
    }
    info
}

fn year_of(text: &str) -> Option<u16> {
    text.split(|c: char| !c.is_ascii_digit())
        .find(|word| word.len() == 4 && (word.starts_with("19") || word.starts_with("20")))
        .and_then(|word| word.parse().ok())
}

fn alternative_titles(document: &Html, title: &str) -> Vec<String> {
    document
        .select(&selector(".infox .alter"))
        .next()
        .map(|span| {
            text_of(span)
                .split(',')
                .map(collapse)
                .filter(|part| !part.is_empty() && part != title)
                .collect()
        })
        .unwrap_or_default()
}

pub fn looks_like_a_detail_page(html: &str) -> bool {
    Html::parse_document(html)
        .select(&selector(".infox h1.entry-title"))
        .next()
        .is_some()
}

pub fn parse_detail(
    html: &str,
    item_id: &str,
    urls: &GogoanimeUrls,
) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let title = document
        .select(&selector(".infox h1.entry-title"))
        .next()
        .map(|heading| collapse(&text_of(heading)))
        .filter(|title| !title.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("detail title was not found".into()))?;
    let info = read_info(&document);
    let known = |key: &str| info.get(key).map(String::as_str).unwrap_or_default();
    let cover_url = document
        .select(&selector(".thumb img"))
        .next()
        .and_then(|image| image.value().attr("src"))
        .and_then(|value| absolute_url(value, urls.base()));
    let latest_label = parse_units(html)
        .into_iter()
        .max_by(|left, right| left.number.total_cmp(&right.number))
        .map(|unit| unit.label);
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(item_id),
            title: title.clone(),
            cover_url,
            latest_label,
        },
        alternative_titles: alternative_titles(&document, &title),
        type_text: known_text(known("type")),
        year: year_of(known("released")).or_else(|| year_of(known("season"))),
        unit_count: first_number(known("episodes")).map(|count| count as u32),
        origin: None,
        synopsis: document
            .select(&selector(".entry-content[itemprop='description']"))
            .next()
            .map(|field| collapse(&text_of(field)))
            .unwrap_or_default(),
        genres: document
            .select(&selector(".genxed a"))
            .map(|link| collapse(&text_of(link)))
            .filter(|genre| !genre.is_empty())
            .collect(),
        catalog_id: None,
        mal_id: None,
    })
}
