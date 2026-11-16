use std::collections::HashMap;

use domain::error::SourceError;
use domain::media::{MediaKind, MediaSummary};
use serde_json::json;

use super::catalog::{media_type, parse};
use super::graphql::GraphQl;
use super::mapper::visible_summaries;
use super::queries::batch_match_query;
use super::schema::RawBatchPage;

pub const MATCH_CHUNK: usize = 15;

async fn match_chunk(
    graphql: &GraphQl,
    kind: MediaKind,
    titles: &[String],
) -> Result<Vec<Vec<MediaSummary>>, SourceError> {
    let mut variables = json!({ "type": media_type(kind) });
    for (index, title) in titles.iter().enumerate() {
        variables[format!("t{index}")] = json!(title);
    }
    let data = graphql
        .run(&batch_match_query(titles.len()), variables)
        .await?;
    let mut pages: HashMap<String, RawBatchPage> = parse(data, "match")?;
    Ok((0..titles.len())
        .map(|index| {
            pages
                .remove(&format!("m{index}"))
                .map(|page| visible_summaries(page.media))
                .unwrap_or_default()
        })
        .collect())
}

type Outcome = Result<Vec<Vec<MediaSummary>>, SourceError>;

async fn two_at_once(
    graphql: &GraphQl,
    kind: MediaKind,
    pair: &[&[String]],
) -> Vec<(usize, Outcome)> {
    let first = match_chunk(graphql, kind, pair[0]);
    let second = async {
        match pair.get(1) {
            Some(chunk) => Some(match_chunk(graphql, kind, chunk).await),
            None => None,
        }
    };
    let (one, two) = tokio::join!(first, second);
    let mut done = vec![(pair[0].len(), one)];
    if let (Some(chunk), Some(outcome)) = (pair.get(1), two) {
        done.push((chunk.len(), outcome));
    }
    done
}

pub async fn match_all(
    graphql: &GraphQl,
    kind: MediaKind,
    titles: &[String],
) -> Result<Vec<Vec<MediaSummary>>, SourceError> {
    let mut found: Vec<Vec<MediaSummary>> = Vec::with_capacity(titles.len());
    let mut failure: Option<SourceError> = None;
    let mut served = 0usize;
    let chunks: Vec<&[String]> = titles.chunks(MATCH_CHUNK).collect();
    for pair in chunks.chunks(2) {
        for (size, outcome) in two_at_once(graphql, kind, pair).await {
            match outcome {
                Ok(part) => {
                    served += 1;
                    found.extend(part);
                }
                Err(error) => {
                    failure.get_or_insert(error);
                    found.extend((0..size).map(|_| Vec::new()));
                }
            }
        }
    }
    match failure {
        Some(error) if served == 0 && !titles.is_empty() => Err(error),
        _ => Ok(found),
    }
}
