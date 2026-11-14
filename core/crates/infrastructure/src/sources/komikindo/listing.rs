use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{
    absolute_url, collapse, known_text, percent_decode, selector, text_of,
};

const COMIC_PATH: &str = "/komik/";

pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub total_pages: u32,
}

fn title_slug(href: &str) -> Option<String> {
    let start = href.find(COMIC_PATH)? + COMIC_PATH.len();
    let rest = &href[start..];
    let end = rest.find(['/', '?', '#']).unwrap_or(rest.len());
    (end > 0).then(|| percent_decode(&rest[..end]))
}

fn read_card(card: ElementRef, base: &Url) -> Option<SourceItem> {
    let href = card
        .select(&selector(".animposx a"))
        .next()?
        .value()
        .attr("href")?;
    let item_id = title_slug(href)?;
    let title = card
        .select(&selector(".bigors .tt"))
        .next()
        .map(|heading| collapse(&text_of(heading)))
        .filter(|title| !title.is_empty())?;
    let image = card.select(&selector("img")).next();
    let cover = image.and_then(|image| {
        image
            .value()
            .attr("src")
            .or(image.value().attr("data-src"))
            .and_then(|source| absolute_url(source, base))
    });
    Some(SourceItem {
        item_id: ItemId::new(item_id),
        title,
        cover_url: cover,
        latest_label: card
            .select(&selector(".lsch a"))
            .next()
            .and_then(|link| known_text(&text_of(link))),
    })
}

fn total_pages(document: &Html) -> u32 {
    document
        .select(&selector(".pagination a.page-numbers"))
        .filter_map(|link| text_of(link).trim().parse::<u32>().ok())
        .max()
        .unwrap_or(1)
        .max(1)
}

fn is_empty_search(document: &Html) -> bool {
    document
        .select(&selector("h1, h2, .widget-title"))
        .any(|heading| text_of(heading).to_lowercase().contains("hasil pencarian"))
}

pub fn parse_listing_page(html: &str, base: &Url) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    if document
        .select(&selector(".listupd .film-list"))
        .next()
        .is_none()
    {
        return if is_empty_search(&document) {
            Ok(ListingPage {
                items: Vec::new(),
                total_pages: 1,
            })
        } else {
            Err(SourceError::MarkupChanged(
                "listing cards were not found".into(),
            ))
        };
    }
    let cards: Vec<ElementRef> = document
        .select(&selector(".listupd .film-list .animepost"))
        .collect();
    let items: Vec<SourceItem> = cards
        .iter()
        .filter_map(|card| read_card(*card, base))
        .collect();
    if items.is_empty() && !cards.is_empty() {
        return Err(SourceError::MarkupChanged("listing data is invalid".into()));
    }
    Ok(ListingPage {
        items,
        total_pages: total_pages(&document),
    })
}
