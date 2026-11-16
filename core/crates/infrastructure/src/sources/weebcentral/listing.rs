use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use super::urls::is_series_code;
use crate::sources::support::{absolute_url, collapse, selector, text_of};

const SERIES_PATH: &str = "/series/";

pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub has_next_page: bool,
}

fn series_id(href: &str) -> Option<String> {
    let start = href.find(SERIES_PATH)? + SERIES_PATH.len();
    let (code, rest) = href[start..].split_once('/')?;
    let slug = rest.split(['/', '?', '#']).next().unwrap_or_default();
    (is_series_code(code) && !slug.is_empty()).then(|| format!("{code}/{slug}"))
}

fn read_card(card: ElementRef, base: &Url) -> Option<SourceItem> {
    let href = card.select(&selector("a")).next()?.value().attr("href")?;
    let id = series_id(href)?;
    let title = card
        .select(&selector("div.truncate"))
        .next()
        .map(|node| collapse(&text_of(node)))
        .filter(|text| !text.is_empty())?;
    let cover = card
        .select(&selector("img"))
        .next()
        .and_then(|image| image.value().attr("src"))
        .and_then(|source| absolute_url(source, base));
    Some(SourceItem {
        item_id: ItemId::new(id),
        title,
        cover_url: cover,
        latest_label: None,
    })
}

pub fn parse_listing_page(html: &str, base: &Url) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    let cards: Vec<ElementRef> = document.select(&selector("article.bg-base-300")).collect();
    if cards.is_empty() {
        return if html.trim().is_empty() || html.contains("alert-warning") {
            Ok(ListingPage {
                items: Vec::new(),
                has_next_page: false,
            })
        } else {
            Err(SourceError::MarkupChanged(
                "listing cards were not found".into(),
            ))
        };
    }
    let mut items: Vec<SourceItem> = Vec::new();
    for item in cards.into_iter().filter_map(|card| read_card(card, base)) {
        if !items.iter().any(|known| known.item_id == item.item_id) {
            items.push(item);
        }
    }
    let has_next_page = document
        .select(&selector("button[hx-get*='offset=']"))
        .next()
        .is_some();
    Ok(ListingPage {
        items,
        has_next_page,
    })
}
