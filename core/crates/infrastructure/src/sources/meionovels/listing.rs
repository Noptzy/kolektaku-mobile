use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use super::title::clean_title;
use crate::sources::support::{
    absolute_url, collapse, is_adult_genre, is_adult_label, known_text, selector, slug_in, text_of,
};

const NOVEL_PATH: &str = "/novel/";
const NO_RESULTS_MARK: &str = "no-results not-found";

pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub has_next_page: bool,
}

pub fn novel_slug(href: &str) -> Option<String> {
    let start = href.find(NOVEL_PATH)? + NOVEL_PATH.len();
    slug_in(&href[start..], &['.', '_', '%'])
}

fn cover_of(card: ElementRef, base: &Url) -> Option<String> {
    let image = card.select(&selector("img")).next()?;
    let value = image.value();
    value
        .attr("src")
        .or(value.attr("data-src"))
        .and_then(|source| absolute_url(source, base))
}

fn is_adult_card(card: ElementRef, title: &str) -> bool {
    let genre_links = selector(".mg_genres .summary-content a");
    let adult_genre = card
        .select(&genre_links)
        .map(text_of)
        .any(|genre| is_adult_genre(&genre));
    is_adult_label(title) || adult_genre
}

fn read_card(card: ElementRef, base: &Url) -> Option<SourceItem> {
    let anchor = card.select(&selector(".post-title a")).next()?;
    let slug = novel_slug(anchor.value().attr("href")?)?;
    let raw = collapse(&text_of(anchor));
    let title = clean_title(&raw);
    if title.is_empty() || is_adult_card(card, &raw) {
        return None;
    }
    Some(SourceItem {
        item_id: ItemId::new(slug),
        title,
        cover_url: cover_of(card, base),
        latest_label: card
            .select(&selector(".chapter-item .chapter a"))
            .next()
            .and_then(|link| known_text(&text_of(link))),
    })
}

pub fn parse_listing_page(html: &str, base: &Url) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    let cards: Vec<ElementRef> = document
        .select(&selector(".page-item-detail, .c-tabs-item__content"))
        .collect();
    if cards.is_empty() {
        return if html.trim().is_empty() || html.contains(NO_RESULTS_MARK) {
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
    let items: Vec<SourceItem> = cards
        .into_iter()
        .filter_map(|card| read_card(card, base))
        .collect();
    let has_next_page = document
        .select(&selector("link[rel=next]"))
        .next()
        .is_some();
    Ok(ListingPage {
        items,
        has_next_page,
    })
}
