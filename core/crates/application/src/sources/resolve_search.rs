use std::sync::Arc;

use domain::media::{MediaRef, MediaSummary};
use domain::source::{SourceId, SourceLink};
use tokio::task::JoinSet;

use super::SourceHealth;
use super::find_link::{Found, find_in_source, verify_item};
use super::merge::{Answer, is_fresh};
use super::search_queries::search_queries;
use crate::matching::{CatalogIds, MATCHER_VERSION, MatchTarget};
use crate::ports::SourceProvider;

fn keep_variants(mut found: Found, previous: &SourceLink) -> Found {
    if found.link.item == previous.item {
        found.link.variants = previous.variants.clone();
    }
    found
}

pub fn unlinked_sources(
    sources: &[Arc<dyn SourceProvider>],
    health: &SourceHealth,
    reference: &MediaRef,
    stored: &[SourceLink],
    now: u64,
) -> Vec<SourceId> {
    sources
        .iter()
        .map(|source| source.info().id.clone())
        .filter(|id| stored.iter().all(|link| link.source != *id))
        .filter(|id| !health.is_skipped(id) && !health.misses().is_recent(reference, id, now))
        .collect()
}

fn record(health: &SourceHealth, reference: &MediaRef, answer: &Answer, now: u64) {
    match &answer.result {
        Ok(found) => {
            health.record_success(&answer.source);
            if found.is_none() {
                health.misses().record(reference, &answer.source, now);
            }
        }
        Err(error) => health.record_failure(&answer.source, error),
    }
}

pub async fn search_sources(
    sources: &[Arc<dyn SourceProvider>],
    health: &SourceHealth,
    media: &MediaSummary,
    stored: &[SourceLink],
    now: u64,
) -> Vec<Answer> {
    let target = MatchTarget::of(media);
    let ids = CatalogIds::of(media);
    let queries = search_queries(media);
    let mut tasks = JoinSet::new();
    for source in sources {
        let id = source.info().id.clone();
        let existing = stored.iter().find(|link| link.source == id);
        if health.is_skipped(&id) || existing.is_some_and(|link| link.manual || is_fresh(link, now))
        {
            continue;
        }
        let unverified = existing
            .filter(|link| link.matcher_version >= MATCHER_VERSION)
            .cloned();
        let (source, target, queries) = (Arc::clone(source), target.clone(), queries.clone());
        tasks.spawn(async move {
            let verified = match unverified {
                Some(link) => verify_item(
                    Arc::clone(&source),
                    target.clone(),
                    ids,
                    link.item.clone(),
                    now,
                )
                .await
                .ok()
                .flatten()
                .map(|found| keep_variants(found, &link)),
                None => None,
            };
            let result = match verified {
                Some(found) => Ok(Some(found)),
                None => find_in_source(source, target, ids, queries, now).await,
            };
            Answer { source: id, result }
        });
    }
    let reference = MediaRef::catalog(media.id);
    let mut answers = Vec::new();
    while let Some(Ok(answer)) = tasks.join_next().await {
        record(health, &reference, &answer, now);
        answers.push(answer);
    }
    answers
}
