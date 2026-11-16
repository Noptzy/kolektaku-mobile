use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{ElementRef, Html};
use url::Url;

use crate::sources::support::{
    absolute_url, collapse, is_adult_label, known_text, selector, slug_in, text_of,
};

const NOVEL_PATH: &str = "/novel/";

pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub has_next_page: bool,
}

fn novel_slug(href: &str) -> Option<String> {
    let start = href.find(NOVEL_PATH)? + NOVEL_PATH.len();
    slug_in(&href[start..], &['.', '_', '%'])
}

fn latest_label(card: ElementRef) -> Option<String> {
    let stats = card.select(&selector(".novel-stats span")).next()?;
    let text = collapse(&text_of(stats));
    let chapters = text.split('\u{b7}').next().unwrap_or_default();
    known_text(chapters)
}

fn read_card(card: ElementRef, base: &Url) -> Option<SourceItem> {
    let href = card.select(&selector("a")).next()?.value().attr("href")?;
    let slug = novel_slug(href)?;
    let title = card
        .select(&selector(".novel-title"))
        .next()
        .map(|node| collapse(&text_of(node)))
        .filter(|text| !text.is_empty())?;
    if is_adult_label(&title) {
        return None;
    }
    let cover = card
        .select(&selector("img"))
        .next()
        .and_then(|image| image.value().attr("src"))
        .and_then(|source| absolute_url(source, base));
    Some(SourceItem {
        item_id: ItemId::new(slug),
        title,
        cover_url: cover,
        latest_label: latest_label(card),
    })
}

pub fn parse_listing_page(html: &str, base: &Url) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    let Some(list) = document.select(&selector("ul.novel-list")).next() else {
        return if html.trim().is_empty() || html.contains("no-results") {
            Ok(ListingPage {
                items: Vec::new(),
                has_next_page: false,
            })
        } else {
            Err(SourceError::MarkupChanged(
                "listing cards were not found".into(),
            ))
        };
    };
    let items = list
        .select(&selector("li.novel-item"))
        .filter_map(|card| read_card(card, base))
        .collect();
    let has_next_page = document.select(&selector("a[rel=next]")).next().is_some();
    Ok(ListingPage {
        items,
        has_next_page,
    })
}
