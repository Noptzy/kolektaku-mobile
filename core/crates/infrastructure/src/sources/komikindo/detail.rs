use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem, Unit};
use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{
    absolute_url, collapse, first_number, known_text, selector, text_of,
};

const PLACEHOLDER_HOST: &str = "https://x.invalid";

fn chapter_id(href: &str) -> Option<String> {
    let path = Url::parse(PLACEHOLDER_HOST)
        .ok()?
        .join(href)
        .ok()?
        .path()
        .to_string();
    let trimmed = path.trim_matches('/');
    (!trimmed.is_empty()).then(|| trimmed.to_string())
}

fn read_chapter(item: ElementRef) -> Option<Unit> {
    let anchor = item.select(&selector("a")).next()?;
    let id = chapter_id(anchor.value().attr("href")?)?;
    let chapter_text = item
        .select(&selector("chapter"))
        .next()
        .map(|tag| collapse(&text_of(tag)))
        .unwrap_or_default();
    let label = if chapter_text.is_empty() {
        collapse(&text_of(anchor))
    } else {
        chapter_text
    };
    let number = first_number(&label)?;
    let shown = if label.starts_with(|c: char| c.is_ascii_digit()) {
        format!("Chapter {label}")
    } else {
        label
    };
    Some(Unit::new(id, number, shown))
}

pub fn parse_chapter_list(html: &str) -> Vec<Unit> {
    let document = Html::parse_document(html);
    let mut chapters: Vec<Unit> = Vec::new();
    for item in document.select(&selector("#chapter_list ul li")) {
        let Some(unit) = read_chapter(item) else {
            continue;
        };
        match chapters.iter().position(|known| known.id == unit.id) {
            Some(index) => chapters[index] = unit,
            None => chapters.push(unit),
        }
    }
    chapters.sort_by(|left, right| left.number.total_cmp(&right.number));
    chapters
}

fn info_value(document: &Html, label: &str) -> String {
    document
        .select(&selector(".infox span"))
        .map(text_of)
        .find(|text| text.contains(label))
        .map(|text| collapse(&text.replacen(label, "", 1)))
        .unwrap_or_default()
}

fn type_flag(document: &Html) -> Option<String> {
    let flag = document
        .select(&selector(".infox .typeflag, .thumb .typeflag"))
        .next()?;
    let classes: Vec<&str> = flag
        .value()
        .classes()
        .filter(|class| *class != "typeflag")
        .collect();
    Some(classes.join(" "))
}

fn page_title(document: &Html) -> String {
    let heading = document
        .select(&selector(".entry-title"))
        .next()
        .map(|title| collapse(&text_of(title)))
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
    let title = page_title(&document);
    if title.is_empty() {
        return Err(SourceError::MarkupChanged(
            "detail title was not found".into(),
        ));
    }
    let chapters = parse_chapter_list(html);
    let alternative_titles = info_value(&document, "Judul Alternatif:")
        .split([',', ';', '/'])
        .map(|part| part.trim().to_string())
        .filter(|part| !part.is_empty() && part != "-" && *part != title)
        .collect();
    let kind = known_text(&info_value(&document, "Jenis Komik:"))
        .or_else(|| type_flag(&document).and_then(|flag| known_text(&flag)));
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(item_id),
            title: title.clone(),
            cover_url: document
                .select(&selector(".thumb img"))
                .next()
                .and_then(|image| image.value().attr("src"))
                .and_then(|source| absolute_url(source, base)),
            latest_label: chapters.last().map(|chapter| chapter.label.clone()),
        },
        alternative_titles,
        type_text: kind,
        year: None,
        unit_count: (!chapters.is_empty()).then_some(chapters.len() as u32),
        origin: None,
        synopsis: collapse(
            &document
                .select(&selector("#sinopsis .entry-content p"))
                .map(text_of)
                .collect::<String>(),
        ),
        genres: document
            .select(&selector(".genre-info a"))
            .map(|anchor| collapse(&text_of(anchor)))
            .filter(|genre| !genre.is_empty())
            .collect(),
        catalog_id: None,
    })
}
