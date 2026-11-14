use domain::matching::Confidence;
use domain::media::{MediaRef, MediaSummary};
use domain::source::{SourceId, SourceItem, SourceLink};

use super::MediaCard;
use crate::matching::{AUTO_CONFIDENCE, Assignment, PageItem, assign_page, title_similarity};

pub struct SiteItems {
    pub source: SourceId,
    pub items: Vec<SourceItem>,
}

pub(super) struct Flat<'a> {
    pub(super) site: usize,
    pub(super) item: &'a SourceItem,
}

pub(super) fn link(source: &SourceId, item: &SourceItem, score: f64, now_secs: u64) -> SourceLink {
    SourceLink::matched(
        source.clone(),
        item.item_id.clone(),
        Confidence::new(score as f32).capped_for_list(),
        now_secs,
    )
}

pub(super) fn catalog_card(
    media: MediaSummary,
    linked: Vec<(&SiteItems, &SourceItem, f64)>,
    now_secs: u64,
) -> MediaCard {
    let first = linked.first().map(|(_, item, _)| *item);
    MediaCard {
        reference: MediaRef::catalog(media.id),
        title: media.title.romaji.clone(),
        cover_url: media
            .cover_url
            .clone()
            .or_else(|| first.and_then(|item| item.cover_url.clone())),
        latest_label: first.and_then(|item| item.latest_label.clone()),
        links: linked
            .iter()
            .map(|(site, item, score)| link(&site.source, item, *score, now_secs))
            .collect(),
        summary: Some(media),
    }
}

pub(super) fn site_card(site: &SiteItems, item: &SourceItem, now_secs: u64) -> MediaCard {
    MediaCard {
        reference: MediaRef::source(site.source.clone(), item.item_id.clone()),
        title: item.title.clone(),
        cover_url: item.cover_url.clone(),
        latest_label: item.latest_label.clone(),
        summary: None,
        links: vec![SourceLink::matched(
            site.source.clone(),
            item.item_id.clone(),
            Confidence::new(1.0),
            now_secs,
        )],
    }
}

fn same_title(left: &str, right: &str) -> f64 {
    title_similarity(&[left.to_string()], right)
}

pub(super) fn fold_into_group(
    cards: &mut [MediaCard],
    site: &SiteItems,
    item: &SourceItem,
    now_secs: u64,
) -> bool {
    for card in cards.iter_mut().filter(|card| card.summary.is_none()) {
        let score = same_title(&card.title, &item.title);
        let taken = card
            .links
            .iter()
            .any(|existing| existing.source == site.source);
        if score >= AUTO_CONFIDENCE && !taken {
            card.links.push(link(&site.source, item, score, now_secs));
            return true;
        }
    }
    false
}

pub(super) fn layout<'a>(
    media: &[MediaSummary],
    sites: &'a [SiteItems],
) -> (Vec<Flat<'a>>, Vec<Assignment>) {
    let flat: Vec<Flat> = sites
        .iter()
        .enumerate()
        .flat_map(|(site, found)| found.items.iter().map(move |item| Flat { site, item }))
        .collect();
    let page_items: Vec<PageItem> = flat
        .iter()
        .map(|entry| PageItem {
            source: sites[entry.site].source.clone(),
            title: entry.item.title.clone(),
        })
        .collect();
    let assignments = assign_page(media, &page_items);
    (flat, assignments)
}

pub(super) fn linked_for<'a>(
    media_index: usize,
    flat: &[Flat<'a>],
    assignments: &[Assignment],
    sites: &'a [SiteItems],
) -> Vec<(&'a SiteItems, &'a SourceItem, f64)> {
    let mut linked: Vec<(usize, &SiteItems, &SourceItem, f64)> = assignments
        .iter()
        .filter(|assignment| assignment.media_index == media_index)
        .map(|assignment| {
            let entry = &flat[assignment.item_index];
            (entry.site, &sites[entry.site], entry.item, assignment.score)
        })
        .collect();
    linked.sort_by_key(|(site, ..)| *site);
    linked
        .into_iter()
        .map(|(_, site, item, score)| (site, item, score))
        .collect()
}

pub fn compose_cards(
    media: Vec<MediaSummary>,
    sites: &[SiteItems],
    now_secs: u64,
) -> Vec<MediaCard> {
    let (flat, assignments) = layout(&media, sites);
    let linked_per_media: Vec<Vec<(&SiteItems, &SourceItem, f64)>> = (0..media.len())
        .map(|index| linked_for(index, &flat, &assignments, sites))
        .collect();
    let mut cards: Vec<MediaCard> = media
        .into_iter()
        .zip(linked_per_media)
        .map(|(entry, linked)| catalog_card(entry, linked, now_secs))
        .collect();
    let taken: Vec<usize> = assignments
        .iter()
        .map(|assignment| assignment.item_index)
        .collect();
    let unassigned = flat
        .iter()
        .enumerate()
        .filter(|(index, _)| !taken.contains(index))
        .map(|(_, entry)| entry);
    for entry in unassigned {
        let site = &sites[entry.site];
        if !fold_into_group(&mut cards, site, entry.item, now_secs) {
            cards.push(site_card(site, entry.item, now_secs));
        }
    }
    cards
}
