use domain::media::{MediaPage, MediaSummary};
use domain::source::{SourceItem, SourcePage};

use crate::matching::loose_similarity;

const KEEP_AT_LEAST: f64 = 0.6;

fn media_similarity(media: &MediaSummary, query: &str) -> f64 {
    media
        .title
        .names()
        .into_iter()
        .chain(media.synonyms.iter().map(String::as_str))
        .map(|name| loose_similarity(query, name))
        .fold(0.0, f64::max)
}

fn kept_in_order<T>(items: Vec<T>, similarity: impl Fn(&T) -> f64) -> Vec<T> {
    let mut scored: Vec<(f64, T)> = items
        .into_iter()
        .map(|item| (similarity(&item), item))
        .filter(|(score, _)| *score >= KEEP_AT_LEAST)
        .collect();
    scored.sort_by(|left, right| right.0.total_cmp(&left.0));
    scored.into_iter().map(|(_, item)| item).collect()
}

pub fn rerank_media(page: MediaPage, query: &str) -> MediaPage {
    MediaPage {
        items: kept_in_order(page.items, |media| media_similarity(media, query)),
        ..page
    }
}

pub fn rerank_items(page: SourcePage, query: &str) -> SourcePage {
    SourcePage {
        items: kept_in_order(page.items, |item: &SourceItem| {
            loose_similarity(query, &item.title)
        }),
        ..page
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaId, MediaKind, MediaTitle};
    use domain::source::ItemId;

    use super::*;

    fn media(id: u64, romaji: &str, synonyms: &[&str]) -> MediaSummary {
        let mut summary = MediaSummary::new(
            MediaId::new(id).unwrap(),
            MediaKind::Anime,
            MediaTitle::new(romaji),
        );
        summary.synonyms = synonyms.iter().map(|name| name.to_string()).collect();
        summary
    }

    #[test]
    fn media_are_kept_by_any_name_and_ordered_by_resemblance() {
        let page = MediaPage {
            items: vec![
                media(1, "Kimi no Suizou wo Tabetai", &[]),
                media(2, "Unrelated", &["Kimi no Na wa"]),
                media(3, "Kimi no Na wa.", &[]),
            ],
            page: 1,
            has_next_page: true,
        };
        let ranked = rerank_media(page, "kimi no nawa");
        let ids: Vec<u64> = ranked.items.iter().map(|item| item.id.get()).collect();
        assert_eq!(ids, vec![2, 3]);
        assert!(ranked.has_next_page);
    }

    #[test]
    fn site_items_are_kept_by_title_and_the_page_info_stays() {
        let page = SourcePage {
            items: vec![
                SourceItem::new(ItemId::new("a"), "One Piece"),
                SourceItem::new(ItemId::new("b"), "Kimi no Na wa."),
            ],
            page: 2,
            total_pages: 5,
        };
        let ranked = rerank_items(page, "kiminonawa");
        assert_eq!(ranked.items.len(), 1);
        assert_eq!(ranked.items[0].item_id.as_str(), "b");
        assert_eq!((ranked.page, ranked.total_pages), (2, 5));
    }
}
