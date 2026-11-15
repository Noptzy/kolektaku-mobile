use std::collections::HashMap;

use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem, Unit};
use scraper::Html;
use url::Url;

use crate::sources::support::{
    absolute_url, collapse, first_number, known_text, selector, text_of,
};

fn read_info(document: &Html) -> HashMap<String, String> {
    let mut info = HashMap::new();
    for row in document.select(&selector(".inftable tr")) {
        let cells: Vec<String> = row
            .select(&selector("td"))
            .map(|cell| collapse(&text_of(cell)))
            .collect();
        let label = cells
            .first()
            .map(|cell| cell.trim_end_matches(':').to_lowercase())
            .unwrap_or_default();
        if let (false, Some(value)) = (label.is_empty(), cells.last()) {
            info.insert(label, value.clone());
        }
    }
    info
}

fn strip_origin(href: &str) -> &str {
    href.strip_prefix("https://")
        .or_else(|| href.strip_prefix("http://"))
        .map_or(href, |rest| {
            rest.find('/').map_or("", |slash| &rest[slash..])
        })
}

fn chapter_id(href: &str) -> Option<String> {
    let path = strip_origin(href);
    let trimmed = path.strip_prefix('/').unwrap_or(path);
    let trimmed = trimmed.strip_suffix('/').unwrap_or(trimmed);
    let valid = !trimmed.is_empty()
        && trimmed
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '_' | '-'));
    valid.then(|| trimmed.to_string())
}

pub fn parse_chapter_list(html: &str) -> Vec<Unit> {
    let document = Html::parse_document(html);
    let mut by_id: Vec<Unit> = Vec::new();
    for anchor in document.select(&selector("#Daftar_Chapter td.judulseries a")) {
        let label = collapse(&text_of(anchor));
        let id = anchor.value().attr("href").and_then(chapter_id);
        let (Some(id), Some(number)) = (id, first_number(&label)) else {
            continue;
        };
        let unit = Unit::new(id, number, label);
        match by_id.iter().position(|known| known.id == unit.id) {
            Some(index) => by_id[index] = unit,
            None => by_id.push(unit),
        }
    }
    by_id.sort_by(|left, right| left.number.total_cmp(&right.number));
    by_id
}

fn alternative_titles(info: &HashMap<String, String>, title: &str) -> Vec<String> {
    info.get("judul alternatif")
        .map(|value| {
            value
                .split([',', ';', '/'])
                .map(|part| part.trim().to_string())
                .filter(|part| !part.is_empty() && part != "-" && part != title)
                .collect()
        })
        .unwrap_or_default()
}

fn page_title(document: &Html, info: &HashMap<String, String>) -> String {
    if let Some(title) = info.get("judul").filter(|title| !title.is_empty()) {
        return title.clone();
    }
    let heading = document
        .select(&selector("h1"))
        .next()
        .map(|h1| collapse(&text_of(h1)))
        .unwrap_or_default();
    match heading.get(..5) {
        Some(prefix) if prefix.eq_ignore_ascii_case("komik") => {
            heading[5..].trim_start().to_string()
        }
        _ => heading,
    }
}

pub fn parse_detail(html: &str, item_id: &str, base: &Url) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let info = read_info(&document);
    let title = page_title(&document, &info);
    if title.is_empty() {
        return Err(SourceError::MarkupChanged(
            "detail title was not found".into(),
        ));
    }
    let chapters = parse_chapter_list(html);
    let genres = document
        .select(&selector(".inftable ul.genre li a"))
        .map(|anchor| collapse(&text_of(anchor)))
        .filter(|genre| !genre.is_empty())
        .collect();
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(item_id),
            title: title.clone(),
            cover_url: document
                .select(&selector(".ims img"))
                .next()
                .and_then(|image| image.value().attr("src"))
                .and_then(|source| absolute_url(source, base)),
            latest_label: chapters.last().map(|chapter| chapter.label.clone()),
        },
        alternative_titles: alternative_titles(&info, &title),
        type_text: info.get("tipe").and_then(|value| known_text(value)),
        year: None,
        unit_count: (!chapters.is_empty()).then_some(chapters.len() as u32),
        origin: None,
        synopsis: document
            .select(&selector("p.desc"))
            .next()
            .map(|paragraph| collapse(&text_of(paragraph)))
            .unwrap_or_default(),
        genres,
        catalog_id: None,
    })
}
