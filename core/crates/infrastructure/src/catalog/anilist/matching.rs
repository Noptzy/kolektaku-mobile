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

pub async fn match_all(
    graphql: &GraphQl,
    kind: MediaKind,
    titles: &[String],
) -> Result<Vec<Vec<MediaSummary>>, SourceError> {
    let mut found: Vec<Vec<MediaSummary>> = Vec::with_capacity(titles.len());
    let mut failure: Option<SourceError> = None;
    let mut served = 0usize;
    for chunk in titles.chunks(MATCH_CHUNK) {
        match match_chunk(graphql, kind, chunk).await {
            Ok(part) => {
                served += 1;
                found.extend(part);
            }
            Err(error) => {
                failure.get_or_insert(error);
                found.extend(chunk.iter().map(|_| Vec::new()));
            }
        }
    }
    match failure {
        Some(error) if served == 0 && !titles.is_empty() => Err(error),
        _ => Ok(found),
    }
}
