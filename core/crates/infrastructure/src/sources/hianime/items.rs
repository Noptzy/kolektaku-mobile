use domain::source::{ItemId, SourceDetail, SourceItem};

use super::model::{RawAnime, number_of};
use super::urls::valid_slug;
use crate::sources::support::is_adult_label;

pub fn slug_of(raw: &RawAnime) -> Option<String> {
    raw.slug
        .clone()
        .or_else(|| raw.slugs.as_ref().and_then(|slugs| slugs.first().cloned()))
        .filter(|slug| valid_slug(slug))
}

fn title_of(raw: &RawAnime) -> Option<String> {
    [&raw.title, &raw.english]
        .into_iter()
        .flatten()
        .map(|text| text.trim())
        .find(|text| !text.is_empty())
        .map(str::to_string)
}

pub fn is_adult(raw: &RawAnime) -> bool {
    let rated = raw
        .rating
        .as_deref()
        .is_some_and(|rating| rating.trim_start().to_lowercase().starts_with("rx"));
    let genres = raw
        .genres
        .as_ref()
        .is_some_and(|genres| genres.iter().any(|genre| is_adult_label(genre)));
    rated || genres
}

fn secure(url: &str) -> Option<String> {
    let trimmed = url.trim();
    trimmed
        .starts_with("https://")
        .then(|| trimmed.to_string())
}

pub fn item_of(raw: &RawAnime) -> Option<SourceItem> {
    if is_adult(raw) {
        return None;
    }
    let slug = slug_of(raw)?;
    let mut item = SourceItem::new(ItemId::new(slug), title_of(raw)?);
    item.cover_url = raw.image.as_deref().and_then(secure);
    item.latest_label = raw
        .total_subbed
        .as_ref()
        .and_then(number_of)
        .filter(|count| *count > 0)
        .map(|count| format!("Episode {count}"));
    Some(item)
}

type Release = (u32, String, String, Option<u32>, Option<String>);

fn release_of(raw: &RawAnime) -> Option<Release> {
    let catalog = raw.mal_id.as_ref().and_then(number_of)?;
    let aired = raw.aired.as_deref()?.trim().to_string();
    if aired.is_empty() {
        return None;
    }
    let kind = raw.kind.clone().unwrap_or_default().trim().to_lowercase();
    let episodes = raw.total_episodes.as_ref().and_then(number_of);
    let native = raw.japanese.as_deref().map(|text| text.trim().to_lowercase());
    Some((catalog, aired, kind, episodes, native))
}

fn plainer(left: &str, right: &str) -> String {
    if right.chars().count() < left.chars().count() {
        right.to_string()
    } else {
        left.to_string()
    }
}

fn is_newer(candidate: &Option<String>, known: &Option<String>) -> bool {
    matches!((candidate, known), (Some(new), Some(old)) if new > old)
}

struct Listing {
    release: Option<Release>,
    created: Option<String>,
    item: SourceItem,
}

pub fn items_of(list: Option<Vec<RawAnime>>) -> Vec<SourceItem> {
    let raws = list.unwrap_or_default();
    let mut entries: Vec<(&RawAnime, SourceItem)> = raws
        .iter()
        .filter_map(|raw| item_of(raw).map(|item| (raw, item)))
        .collect();
    entries.sort_by_key(|(_, item)| item.title.to_lowercase().contains("(uncensored)"));
    let mut kept: Vec<Listing> = Vec::new();
    for (raw, item) in entries {
        let release = release_of(raw);
        let created = raw.created_at.clone();
        let twin = release
            .as_ref()
            .and_then(|wanted| kept.iter().position(|known| known.release.as_ref() == Some(wanted)));
        match twin {
            Some(at) => {
                let name = plainer(&kept[at].item.title, &item.title);
                if is_newer(&created, &kept[at].created) {
                    kept[at].item = item;
                    kept[at].created = created;
                }
                kept[at].item.title = name;
            }
            None => kept.push(Listing {
                release,
                created,
                item,
            }),
        }
    }
    kept.into_iter().map(|listing| listing.item).collect()
}

pub fn year_of(aired: &str) -> Option<u16> {
    aired
        .split(|c: char| !c.is_ascii_digit())
        .filter(|part| part.len() == 4)
        .filter_map(|part| part.parse::<u16>().ok())
        .find(|year| (1900..=2100).contains(year))
}

fn extras(raw: &RawAnime, title: &str) -> Vec<String> {
    let mut titles: Vec<String> = Vec::new();
    for text in [&raw.english, &raw.japanese, &raw.alternate_title]
        .into_iter()
        .flatten()
    {
        let text = text.trim();
        if !text.is_empty() && text != title && !titles.iter().any(|known| known == text) {
            titles.push(text.to_string());
        }
    }
    titles
}

pub fn detail_of(raw: &RawAnime) -> Option<SourceDetail> {
    let item = SourceItem {
        latest_label: None,
        ..item_of(raw)?
    };
    let mut detail = SourceDetail::new(item);
    detail.alternative_titles = extras(raw, &detail.item.title);
    detail.type_text = raw.kind.clone().filter(|kind| !kind.trim().is_empty());
    detail.year = raw.aired.as_deref().and_then(year_of);
    detail.unit_count = raw.total_episodes.as_ref().and_then(number_of);
    detail.synopsis = raw.synopsis.clone().unwrap_or_default().trim().to_string();
    detail.genres = raw.genres.clone().unwrap_or_default();
    Some(detail)
}
