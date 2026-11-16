use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{ElementRef, Html};

use super::urls::GogoanimeUrls;
use crate::sources::support::{absolute_url, collapse, known_text, selector, text_of};

const STATUS_WORDS: [&str; 4] = ["completed", "ongoing", "upcoming", "hiatus"];

#[derive(Debug)]
pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub total_pages: u32,
}

fn label_of(card: ElementRef) -> Option<String> {
    let text = card
        .select(&selector(".epx"))
        .next()
        .and_then(|label| known_text(&text_of(label)))?;
    (!STATUS_WORDS.contains(&text.to_lowercase().as_str())).then_some(text)
}

fn read_card(card: ElementRef, urls: &GogoanimeUrls) -> Option<SourceItem> {
    let anchor = card.select(&selector("a[href]")).next()?;
    let slug = urls.anime_slug(anchor.value().attr("href")?)?;
    let title = card
        .select(&selector(".tt h2"))
        .next()
        .map(|heading| collapse(&text_of(heading)))
        .filter(|title| !title.is_empty())
        .or_else(|| anchor.value().attr("title").map(collapse))
        .filter(|title| !title.is_empty())?;
    let cover_url = card
        .select(&selector("img"))
        .next()
        .and_then(|image| image.value().attr("src").or(image.value().attr("data-src")))
        .and_then(|value| absolute_url(value, urls.base()));
    Some(SourceItem {
        item_id: ItemId::new(slug),
        title,
        cover_url,
        latest_label: label_of(card),
    })
}

fn numbered_pages(document: &Html) -> Option<u32> {
    document
        .select(&selector(
            ".pagination a.page-numbers, .pagination span.page-numbers",
        ))
        .filter_map(|link| text_of(link).trim().parse::<u32>().ok())
        .max()
}

fn total_pages(document: &Html, page: u32) -> u32 {
    if let Some(last) = numbered_pages(document) {
        return last.max(page);
    }
    let has_next = document.select(&selector(".hpage a.r")).next().is_some();
    if has_next { page + 1 } else { page.max(1) }
}

pub fn parse_listing(
    html: &str,
    urls: &GogoanimeUrls,
    page: u32,
) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    let list = document
        .select(&selector(".listupd"))
        .next()
        .ok_or_else(|| SourceError::MarkupChanged("listing was not found".into()))?;
    let cards: Vec<ElementRef> = list.select(&selector("article.bs")).collect();
    let items: Vec<SourceItem> = cards
        .iter()
        .filter_map(|card| read_card(*card, urls))
        .collect();
    if items.is_empty() && !cards.is_empty() {
        return Err(SourceError::MarkupChanged("listing data is invalid".into()));
    }
    Ok(ListingPage {
        items,
        total_pages: total_pages(&document, page),
    })
}
