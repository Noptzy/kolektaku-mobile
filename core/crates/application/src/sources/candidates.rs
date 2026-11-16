use std::sync::Arc;

use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceSearch};
use tokio::task::JoinSet;

use crate::matching::{AUTO_CONFIDENCE, CandidateFacts, ListedCandidate, MatchTarget, score_title};
use crate::ports::SourceProvider;

pub fn facts_of(detail: &SourceDetail) -> CandidateFacts {
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

pub async fn listed_candidates(
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

pub async fn details_in_order(
    source: &Arc<dyn SourceProvider>,
    keys: &[String],
) -> Vec<(String, Result<SourceDetail, SourceError>)> {
    let mut tasks = JoinSet::new();
    for key in keys {
        let source = Arc::clone(source);
        let key = key.clone();
        tasks.spawn(async move {
            let detail = source.detail(ItemId::new(key.clone())).await;
            (key, detail)
        });
    }
    let mut details = Vec::new();
    while let Some(Ok(entry)) = tasks.join_next().await {
        details.push(entry);
    }
    details.sort_by_key(|(key, _)| keys.iter().position(|known| known == key));
    details
}
