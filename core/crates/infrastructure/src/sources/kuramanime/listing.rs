use domain::error::SourceError;
use domain::source::{ItemId, SourceItem};
use scraper::{CaseSensitivity, ElementRef, Html};
use url::Url;

use super::ids::anime_path;
use crate::sources::support::{absolute_url, collapse, known_text, selector, text_of};

const TITLE_SELECTORS: [&str; 2] = [".sidebar-title-h5", ".product__item__text h5"];
const COVER_SELECTORS: [&str; 2] = [".product__sidebar__view__item", ".product__item__pic"];

pub struct ListingPage {
    pub items: Vec<SourceItem>,
    pub total_pages: u32,
}

fn is_legacy_card(anchor: &ElementRef) -> bool {
    let in_gallery = anchor
        .parent()
        .and_then(ElementRef::wrap)
        .is_some_and(|parent| {
            parent
                .value()
                .has_class("filter__gallery", CaseSensitivity::CaseSensitive)
        });
    in_gallery
        || anchor
            .select(&selector(".product__sidebar__view__item"))
            .next()
            .is_some()
}

fn card_roots(document: &Html) -> Vec<ElementRef<'_>> {
    let current = selector("#animeList .product__item");
    let anchors = selector("#animeList a");
    let mut roots: Vec<ElementRef> = document.select(&current).collect();
    roots.extend(document.select(&anchors).filter(is_legacy_card));
    roots
}

fn first_match<'a>(root: ElementRef<'a>, selectors: &[&str]) -> Option<ElementRef<'a>> {
    selectors
        .iter()
        .find_map(|css| root.select(&selector(css)).next())
}

fn link_of(root: ElementRef) -> Option<String> {
    let anchor = if root.value().name() == "a" {
        root
    } else {
        root.select(&selector("a[href*='/anime/']")).next()?
    };
    anchor.value().attr("href").map(str::to_string)
}

fn read_card(root: ElementRef, base: &Url) -> Option<SourceItem> {
    let item_id = anime_path(&link_of(root)?)?;
    let title = first_match(root, &TITLE_SELECTORS)
        .map(|heading| collapse(&text_of(heading)))
        .filter(|title| !title.is_empty())?;
    let cover_url = first_match(root, &COVER_SELECTORS)
        .and_then(|poster| poster.value().attr("data-setbg"))
        .and_then(|value| absolute_url(value, base));
    let latest_label = root
        .select(&selector(".ep"))
        .next()
        .and_then(|label| known_text(&text_of(label)));
    Some(SourceItem {
        item_id: ItemId::new(item_id),
        title,
        cover_url,
        latest_label,
    })
}

fn page_of_link(href: &str) -> Option<u32> {
    let start = href.find("page=")? + "page=".len();
    let digits: String = href[start..]
        .chars()
        .take_while(char::is_ascii_digit)
        .collect();
    digits.parse().ok()
}

fn total_pages(document: &Html) -> u32 {
    document
        .select(&selector(
            ".product__pagination a.page__link, .product__pagination a.current-page",
        ))
        .flat_map(|link| {
            let shown = text_of(link).trim().parse::<u32>().ok();
            let target = link.value().attr("href").and_then(page_of_link);
            [shown, target]
        })
        .flatten()
        .max()
        .unwrap_or(1)
        .max(1)
}

pub fn parse_listing_page(html: &str, base: &Url) -> Result<ListingPage, SourceError> {
    let document = Html::parse_document(html);
    let roots = card_roots(&document);
    if roots.is_empty() {
        let empty_note = document.select(&selector("#animeList #emptyText")).next();
        return match empty_note {
            Some(_) => Ok(ListingPage {
                items: Vec::new(),
                total_pages: 1,
            }),
            None => Err(SourceError::MarkupChanged(
                "listing cards were not found".into(),
            )),
        };
    }
    let items: Vec<SourceItem> = roots
        .into_iter()
        .filter_map(|root| read_card(root, base))
        .collect();
    if items.is_empty() {
        return Err(SourceError::MarkupChanged("listing data is invalid".into()));
    }
    Ok(ListingPage {
        items,
        total_pages: total_pages(&document),
    })
}
