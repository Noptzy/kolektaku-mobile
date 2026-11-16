use std::collections::HashMap;
use std::sync::Arc;

use domain::error::SourceError;
use domain::matching::Confidence;
use domain::source::{ItemId, LinkVariant, SourceLink};

use super::candidates::{details_in_order, facts_of, listed_candidates};
use super::variants::{split_variants, variants_of};
use crate::matching::{
    CandidateFacts, CatalogIds, MATCHER_VERSION, MatchDecision, MatchTarget, PickedCandidate,
    Verdict, VerifiedCandidate, audio_variant_of, pick_best_candidate, shortlist_candidates,
    tie_rank,
};
use crate::ports::SourceProvider;

#[derive(Debug, Clone, PartialEq)]
pub struct Found {
    pub link: SourceLink,
    pub needs_hint: bool,
}

fn found_from(
    source: &dyn SourceProvider,
    picked: PickedCandidate,
    title: &str,
    unit_count: Option<u32>,
    variants: Vec<LinkVariant>,
    now_secs: u64,
) -> Found {
    let link = SourceLink::matched(
        source.info().id.clone(),
        ItemId::new(picked.key),
        Confidence::new(picked.confidence as f32),
        now_secs,
    )
    .with_title(title)
    .with_unit_count(unit_count)
    .with_variants(variants)
    .with_matcher_version(MATCHER_VERSION);
    Found {
        link,
        needs_hint: picked.decision == MatchDecision::AutoWithHint,
    }
}

fn certain(key: String) -> PickedCandidate {
    PickedCandidate {
        key,
        confidence: 1.0,
        decision: MatchDecision::Auto,
    }
}

fn first_by_rank(target: &MatchTarget, sure: Vec<(String, CandidateFacts)>) -> Option<String> {
    let mut best: Option<(String, _)> = None;
    for (key, facts) in sure {
        let rank = tie_rank(target, &facts);
        if best.as_ref().is_none_or(|(_, current)| rank < *current) {
            best = Some((key, rank));
        }
    }
    best.map(|(key, _)| key)
}

pub async fn find_in_source(
    source: Arc<dyn SourceProvider>,
    target: MatchTarget,
    ids: CatalogIds,
    queries: Vec<String>,
    now_secs: u64,
) -> Result<Option<Found>, SourceError> {
    let listed = listed_candidates(&source, &target, &queries).await?;
    let split = split_variants(listed);
    let shortlist = shortlist_candidates(&target, &split.primaries);
    let keys: Vec<String> = shortlist.iter().map(|entry| entry.key.clone()).collect();
    let mut unit_counts: HashMap<String, Option<u32>> = HashMap::new();
    let mut verified = Vec::new();
    let mut sure: Vec<(String, CandidateFacts)> = Vec::new();
    for (key, detail) in details_in_order(&source, &keys).await {
        let Ok(detail) = detail else { continue };
        unit_counts.insert(key.clone(), detail.unit_count);
        let facts = facts_of(&detail);
        match ids.verdict(detail.catalog_id, detail.mal_id) {
            Verdict::Certain => sure.push((key, facts)),
            Verdict::Refused => {}
            Verdict::Judge => verified.push(VerifiedCandidate { key, facts }),
        }
    }
    let picked = match first_by_rank(&target, sure) {
        Some(key) => Some(certain(key)),
        None => pick_best_candidate(&target, &verified),
    };
    Ok(picked.map(|picked| {
        let units = unit_counts.get(&picked.key).copied().flatten();
        let title = shortlist
            .iter()
            .find(|entry| entry.key == picked.key)
            .map_or("", |entry| entry.title.as_str());
        let variants = variants_of(title, &split.variants);
        found_from(source.as_ref(), picked, title, units, variants, now_secs)
    }))
}

pub async fn verify_item(
    source: Arc<dyn SourceProvider>,
    target: MatchTarget,
    ids: CatalogIds,
    item: ItemId,
    now_secs: u64,
) -> Result<Option<Found>, SourceError> {
    let detail = source.detail(item.clone()).await?;
    if audio_variant_of(&detail.item.title).is_some() {
        return Ok(None);
    }
    match ids.verdict(detail.catalog_id, detail.mal_id) {
        Verdict::Certain => {
            let picked = certain(item.to_string());
            return Ok(Some(found_from(
                source.as_ref(),
                picked,
                &detail.item.title,
                detail.unit_count,
                Vec::new(),
                now_secs,
            )));
        }
        Verdict::Refused => return Ok(None),
        Verdict::Judge => {}
    }
    let candidate = VerifiedCandidate {
        key: item.to_string(),
        facts: facts_of(&detail),
    };
    Ok(pick_best_candidate(&target, &[candidate]).map(|picked| {
        let title = detail.item.title.as_str();
        found_from(
            source.as_ref(),
            picked,
            title,
            detail.unit_count,
            Vec::new(),
            now_secs,
        )
    }))
}
