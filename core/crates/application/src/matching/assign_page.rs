use std::collections::HashSet;

use domain::media::MediaSummary;
use domain::source::SourceId;

use super::score::MINIMUM_CONFIDENCE;
use super::similarity::title_similarity;

const SYNONYM_WEIGHT: f64 = 0.9;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PageItem {
    pub source: SourceId,
    pub title: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Assignment {
    pub item_index: usize,
    pub media_index: usize,
    pub score: f64,
}

fn best_against(names: impl Iterator<Item = String>, title: &str, weight: f64) -> f64 {
    names
        .filter(|name| !name.trim().is_empty())
        .map(|name| title_similarity(&[name], title) * weight)
        .fold(0.0, f64::max)
}

fn pair_score(media: &MediaSummary, title: &str) -> f64 {
    let main = media.title.names().into_iter().map(str::to_string);
    let synonyms = media.synonyms.iter().cloned();
    best_against(main, title, 1.0).max(best_against(synonyms, title, SYNONYM_WEIGHT))
}

pub fn assign_page(media: &[MediaSummary], items: &[PageItem]) -> Vec<Assignment> {
    let mut candidates: Vec<Assignment> = Vec::new();
    for (media_index, entry) in media.iter().enumerate() {
        for (item_index, item) in items.iter().enumerate() {
            let score = pair_score(entry, &item.title);
            if score >= MINIMUM_CONFIDENCE {
                candidates.push(Assignment {
                    item_index,
                    media_index,
                    score,
                });
            }
        }
    }
    candidates.sort_by(|left, right| {
        right
            .score
            .total_cmp(&left.score)
            .then(left.media_index.cmp(&right.media_index))
            .then(left.item_index.cmp(&right.item_index))
    });
    let mut used_items: HashSet<usize> = HashSet::new();
    let mut used_slots: HashSet<(SourceId, usize)> = HashSet::new();
    let mut chosen = Vec::new();
    for candidate in candidates {
        let slot = (
            items[candidate.item_index].source.clone(),
            candidate.media_index,
        );
        if used_items.contains(&candidate.item_index) || used_slots.contains(&slot) {
            continue;
        }
        used_items.insert(candidate.item_index);
        used_slots.insert(slot);
        chosen.push(candidate);
    }
    chosen
}
