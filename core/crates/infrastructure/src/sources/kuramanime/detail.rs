use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use super::episodes::parse_episode_page;
use crate::sources::support::{
    absolute_url, collapse, first_number, known_text, selector, text_of,
};

fn read_info(document: &Html) -> HashMap<String, String> {
    let mut info = HashMap::new();
    for row in document.select(&selector(".anime__details__widget li")) {
        let label = row_text(row, ".col-3")
            .replace(':', "")
            .trim()
            .to_lowercase();
        if !label.is_empty() {
            info.insert(label, collapse(&row_text(row, ".col-9")));
        }
    }
    info
}

fn row_text(row: ElementRef, css: &str) -> String {
    row.select(&selector(css)).map(text_of).collect()
}

pub(super) fn find_year(text: &str) -> Option<u16> {
    text.split(|c: char| !(c.is_alphanumeric() || c == '_'))
        .find(|word| {
            word.len() == 4
                && (word.starts_with("19") || word.starts_with("20"))
                && word.chars().all(|c| c.is_ascii_digit())
        })
        .and_then(|word| word.parse().ok())
}

fn read_genres(document: &Html) -> Vec<String> {
    document
        .select(&selector(".anime__details__widget li"))
        .filter(|row| row_text(*row, ".col-3").to_lowercase().contains("genre"))
        .flat_map(|row| {
            row.select(&selector(".col-9 a"))
                .map(|link| {
                    text_of(link)
                        .trim()
                        .trim_end_matches(',')
                        .trim()
                        .to_string()
                })
                .collect::<Vec<_>>()
        })
        .filter(|genre| !genre.is_empty())
        .collect()
}

fn alternative_titles(document: &Html, title: &str) -> Vec<String> {
    document
        .select(&selector(".anime__details__title > span"))
        .next()
        .map(|span| {
            text_of(span)
                .split(',')
                .map(|part| part.trim().to_string())
                .filter(|part| !part.is_empty() && part != title)
                .collect()
        })
        .unwrap_or_default()
}

fn latest_label(html: &str) -> Option<String> {
    parse_episode_page(html)
        .episodes
        .into_iter()
        .max_by(|left, right| left.number.total_cmp(&right.number))
        .map(|unit| unit.label)
}

pub fn looks_like_a_detail_page(html: &str) -> bool {
    Html::parse_document(html)
        .select(&selector(".anime__details__title h3"))
        .next()
        .is_some()
}

pub fn parse_detail(html: &str, item_id: &str, base: &Url) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let title = document
        .select(&selector(".anime__details__title h3"))
        .next()
        .map(|heading| text_of(heading).trim().to_string())
        .filter(|title| !title.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("detail title was not found".into()))?;
    let info = read_info(&document);
    let info_text = |key: &str| info.get(key).map(String::as_str).unwrap_or_default();
    let cover_url = document
        .select(&selector(
            ".anime__details__pic__mobile, .anime__details__pic",
        ))
        .next()
        .and_then(|pic| pic.value().attr("data-setbg"))
        .and_then(|value| absolute_url(value, base));
    let year_source = format!("{} {}", info_text("tayang"), info_text("musim"));
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(item_id),
            title: title.clone(),
            cover_url,
            latest_label: latest_label(html),
        },
        alternative_titles: alternative_titles(&document, &title),
        type_text: known_text(info_text("tipe")),
        year: find_year(&year_source),
        unit_count: first_number(info_text("episode")).map(|count| count as u32),
        origin: known_text(info_text("negara")).map(|origin| origin.to_uppercase()),
        synopsis: document
            .select(&selector("#synopsisField"))
            .next()
            .map(|field| collapse(&text_of(field)))
            .unwrap_or_default(),
        genres: read_genres(&document),
        catalog_id: None,
        mal_id: None,
    })
}
