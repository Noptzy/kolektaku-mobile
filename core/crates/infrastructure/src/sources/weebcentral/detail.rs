use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{
    absolute_url, collapse, is_adult_genre, known_text, selector, text_of,
};

fn row_value(document: &Html, label: &str) -> Option<String> {
    for item in document.select(&selector("li")) {
        let Some(strong) = item.select(&selector("strong")).next() else {
            continue;
        };
        if collapse(&text_of(strong)).trim_end_matches(':') == label {
            let whole = collapse(&text_of(item));
            let value = whole.strip_prefix(&collapse(&text_of(strong)))?;
            return known_text(value);
        }
    }
    None
}

fn catalog_number(document: &Html) -> Option<u64> {
    document
        .select(&selector("a[href*='anilist.co/manga/']"))
        .filter_map(|anchor| anchor.value().attr("href"))
        .filter_map(|href| href.split("/manga/").nth(1))
        .filter_map(|rest| {
            let digits: String = rest.chars().take_while(char::is_ascii_digit).collect();
            digits.parse::<u64>().ok()
        })
        .find(|number| *number > 0)
}

fn tags(document: &Html) -> Vec<String> {
    let Some(item) = document.select(&selector("li")).find(|item| {
        item.select(&selector("strong"))
            .next()
            .is_some_and(|strong| text_of(strong).contains("Tags"))
    }) else {
        return Vec::new();
    };
    item.select(&selector("a"))
        .map(|anchor| collapse(&text_of(anchor)))
        .filter(|tag| !tag.is_empty())
        .collect()
}

fn description(document: &Html) -> String {
    document
        .select(&selector("li p"))
        .map(|paragraph: ElementRef| collapse(&text_of(paragraph)))
        .find(|text| !text.is_empty())
        .unwrap_or_default()
}

pub fn parse_detail(html: &str, item_id: &str, base: &Url) -> Result<SourceDetail, SourceError> {
    let document = Html::parse_document(html);
    let title = document
        .select(&selector("h1"))
        .next()
        .map(|node| collapse(&text_of(node)))
        .filter(|text| !text.is_empty())
        .ok_or_else(|| SourceError::MarkupChanged("detail title was not found".into()))?;
    let genres = tags(&document);
    if genres.iter().any(|genre| is_adult_genre(genre)) {
        return Err(SourceError::NotFound(item_id.to_string()));
    }
    let cover = document
        .select(&selector("img[src*='/cover/']"))
        .next()
        .and_then(|image| image.value().attr("src"))
        .and_then(|source| absolute_url(source, base));
    Ok(SourceDetail {
        item: SourceItem {
            item_id: ItemId::new(item_id),
            title,
            cover_url: cover,
            latest_label: None,
        },
        alternative_titles: Vec::new(),
        type_text: row_value(&document, "Type"),
        year: row_value(&document, "Released").and_then(|text| text.parse().ok()),
        unit_count: None,
        origin: None,
        synopsis: description(&document),
        genres,
        catalog_id: catalog_number(&document),
    })
}
