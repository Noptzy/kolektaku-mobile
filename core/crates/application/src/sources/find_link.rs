use std::collections::HashMap;
use std::sync::Arc;

use domain::error::SourceError;
use domain::matching::Confidence;
use domain::source::{ItemId, SourceDetail, SourceLink, SourceSearch};
use tokio::task::JoinSet;

use crate::matching::{
    AUTO_CONFIDENCE, CandidateFacts, ListedCandidate, MatchDecision, MatchTarget, PickedCandidate,
    VerifiedCandidate, pick_best_candidate, score_title, shortlist_candidates,
};
use crate::ports::SourceProvider;

#[derive(Debug, Clone, PartialEq)]
pub struct Found {
    pub link: SourceLink,
    pub needs_hint: bool,
}

fn facts_of(detail: &SourceDetail) -> CandidateFacts {
    let titles = std::iter::once(detail.item.title.clone())
        .chain(detail.alternative_titles.iter().cloned())
        .collect();
    CandidateFacts {
        titles,
        type_text: detail.type_text.clone(),
        year: detail.year,
        unit_count: detail.unit_count,
    }
}

fn found_from(
    source: &dyn SourceProvider,
    picked: PickedCandidate,
    unit_count: Option<u32>,
    now_secs: u64,
) -> Found {
    let link = SourceLink::matched(
        source.info().id.clone(),
        ItemId::new(picked.key),
        Confidence::new(picked.confidence as f32),
        now_secs,
    )
    .with_unit_count(unit_count);
    Found {
        link,
        needs_hint: picked.decision == MatchDecision::AutoWithHint,
    }
}

async fn listed_candidates(
    source: &Arc<dyn SourceProvider>,
    target: &MatchTarget,
    queries: &[String],
) -> Result<Vec<ListedCandidate>, SourceError> {
    let mut listed: Vec<ListedCandidate> = Vec::new();
    let mut answered = false;
    let mut failure: Option<SourceError> = None;
    for query in queries {
        match source.search(SourceSearch::new(query.clone())).await {
            Err(error) => failure = failure.or(Some(error)),
            Ok(page) => {
                answered = true;
                for item in page.items {
                    let key = item.item_id.to_string();
                    if !listed.iter().any(|known| known.key == key) {
                        listed.push(ListedCandidate {
                            key,
                            title: item.title,
                        });
                    }
                }
                let best = listed
                    .iter()
                    .map(|known| score_title(target, &known.title))
                    .fold(0.0, f64::max);
                if best >= AUTO_CONFIDENCE {
                    break;
                }
            }
        }
    }
    if answered {
        Ok(listed)
    } else {
        Err(failure.unwrap_or_else(|| SourceError::Network("the site did not answer".into())))
    }
}

async fn details_of(
    source: &Arc<dyn SourceProvider>,
    keys: Vec<String>,
) -> Vec<(String, Result<SourceDetail, SourceError>)> {
    let mut tasks = JoinSet::new();
    for key in keys {
        let source = Arc::clone(source);
        tasks.spawn(async move {
            let detail = source.detail(ItemId::new(key.clone())).await;
            (key, detail)
        });
    }
    let mut details = Vec::new();
    while let Some(Ok(entry)) = tasks.join_next().await {
        details.push(entry);
    }
    details
}

enum Verdict {
    Certain,
    Refused,
    Judge,
}

fn verdict(detail: &SourceDetail, catalog_id: u64) -> Verdict {
    match detail.catalog_id {
        Some(known) if known == catalog_id => Verdict::Certain,
        Some(_) => Verdict::Refused,
        None => Verdict::Judge,
    }
}

fn certain(key: String) -> PickedCandidate {
    PickedCandidate {
        key,
        confidence: 1.0,
        decision: MatchDecision::Auto,
    }
}

pub async fn find_in_source(
    source: Arc<dyn SourceProvider>,
    target: MatchTarget,
    catalog_id: u64,
    queries: Vec<String>,
    now_secs: u64,
) -> Result<Option<Found>, SourceError> {
    let listed = listed_candidates(&source, &target, &queries).await?;
    let shortlist = shortlist_candidates(&target, &listed);
    let keys = shortlist
        .into_iter()
        .map(|candidate| candidate.key)
        .collect();
    let mut unit_counts: HashMap<String, Option<u32>> = HashMap::new();
    let mut verified = Vec::new();
    let mut sure: Vec<String> = Vec::new();
    for (key, detail) in details_of(&source, keys).await {
        let Ok(detail) = detail else { continue };
        unit_counts.insert(key.clone(), detail.unit_count);
        match verdict(&detail, catalog_id) {
            Verdict::Certain => sure.push(key),
            Verdict::Refused => {}
            Verdict::Judge => verified.push(VerifiedCandidate {
                key,
                facts: facts_of(&detail),
            }),
        }
    }
    sure.sort();
    if let Some(key) = sure.into_iter().next() {
        let units = unit_counts.get(&key).copied().flatten();
        return Ok(Some(found_from(
            source.as_ref(),
            certain(key),
            units,
            now_secs,
        )));
    }
    verified.sort_by(|left, right| left.key.cmp(&right.key));
    Ok(pick_best_candidate(&target, &verified).map(|picked| {
        let units = unit_counts.get(&picked.key).copied().flatten();
        found_from(source.as_ref(), picked, units, now_secs)
    }))
}

pub async fn verify_item(
    source: Arc<dyn SourceProvider>,
    target: MatchTarget,
    catalog_id: u64,
    item: ItemId,
    now_secs: u64,
) -> Result<Option<Found>, SourceError> {
    let detail = source.detail(item.clone()).await?;
    match verdict(&detail, catalog_id) {
        Verdict::Certain => {
            let picked = certain(item.to_string());
            return Ok(Some(found_from(
                source.as_ref(),
                picked,
                detail.unit_count,
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
    Ok(pick_best_candidate(&target, &[candidate])
        .map(|picked| found_from(source.as_ref(), picked, detail.unit_count, now_secs)))
}
