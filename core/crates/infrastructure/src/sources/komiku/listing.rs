use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{
    absolute_url, collapse, is_adult_label, known_text, selector, slug_in, text_excluding, text_of,
};

const MANGA_PATH: &str = "/manga/";

pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub has_next_page: bool,
}

enum Card {
    Item(SourceItem),
    Hidden,
    Invalid,
}

fn title_slug(href: &str) -> Option<String> {
    let start = href.find(MANGA_PATH)? + MANGA_PATH.len();
    slug_in(&href[start..], &['.', '_'])
}

fn latest_label(card: ElementRef) -> Option<String> {
    card.select(&selector(".new1"))
        .find(|row| text_of(*row).to_lowercase().contains("terbaru"))
        .and_then(|row| row.select(&selector("span")).last())
        .and_then(|span| known_text(&text_of(span)))
}

fn image_source(card: ElementRef) -> Option<String> {
    let image = card.select(&selector(".bgei img")).next()?;
    let value = image.value();
    value
        .attr("src")
        .or(value.attr("data-src"))
        .map(str::to_string)
}

fn read_card(card: ElementRef, base: &Url) -> Option<Card> {
    let href = card
        .select(&selector(".bgei a"))
        .next()
        .or_else(|| card.select(&selector(".kan a")).next())
        .and_then(|anchor| anchor.value().attr("href"))?;
    let item_id = title_slug(href)?;
    let theme = card
        .select(&selector(".tpe1_inf"))
        .next()
        .map(|info| collapse(&text_excluding(info, "b")))
        .unwrap_or_default();
    if is_adult_label(&theme) {
        return Some(Card::Hidden);
    }
    let title = card
        .select(&selector(".kan h3"))
        .next()
        .map(|heading| collapse(&text_of(heading)))
        .unwrap_or_default();
    if title.is_empty() {
        return Some(Card::Invalid);
    }
    Some(Card::Item(SourceItem {
        item_id: ItemId::new(item_id),
        title,
        cover_url: image_source(card).and_then(|source| absolute_url(&source, base)),
        latest_label: latest_label(card),
    }))
}

fn looks_like_a_listing(html: &str, document: &Html) -> bool {
    let markers = ["hxloading", "hx-get", "class=\"bge\"", "class=\"no-results\""];
    let body_text = document
        .select(&selector("body"))
        .next()
        .map(|body| text_of(body).trim().to_string())
        .unwrap_or_default();
    html.trim().is_empty()
        || body_text.is_empty()
        || markers.iter().any(|marker| html.contains(marker))
}

pub fn parse_listing_page(html: &str, base: &Url) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    let cards: Vec<ElementRef> = document.select(&selector(".bge")).collect();
    if cards.is_empty() {
        return if looks_like_a_listing(html, &document) {
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
    let mut items = Vec::new();
    let mut invalid = 0;
    for card in cards {
        match read_card(card, base) {
            Some(Card::Item(item)) => items.push(item),
            Some(Card::Invalid) => invalid += 1,
            Some(Card::Hidden) | None => {}
        }
    }
    if items.is_empty() && invalid > 0 {
        return Err(SourceError::MarkupChanged("listing data is invalid".into()));
    }
    let has_next_page = document
        .select(&selector("span[hx-get*='/page/']"))
        .next()
        .is_some();
    Ok(ListingPage {
        items,
        has_next_page,
    })
}
