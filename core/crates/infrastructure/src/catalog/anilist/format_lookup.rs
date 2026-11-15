use domain::error::SourceError;
use domain::media::{MediaFormat, MediaId};
use serde::Deserialize;
use serde_json::json;

use super::catalog::parse;
use super::graphql::GraphQl;
use super::schema::lenient;

const QUERY: &str = "
query ($ids: [Int], $perPage: Int) {
  Page(page: 1, perPage: $perPage) {
    media(id_in: $ids, type: MANGA) { id format }
  }
}";

#[derive(Deserialize)]
struct RawFormatResponse {
    #[serde(rename = "Page")]
    page: RawFormatPage,
}

#[derive(Deserialize)]
struct RawFormatPage {
    media: Vec<RawFormatEntry>,
}

#[derive(Deserialize)]
struct RawFormatEntry {
    id: MediaId,
    #[serde(default, deserialize_with = "lenient")]
    format: Option<MediaFormat>,
}

pub async fn fetch_comic_formats(
    graphql: &GraphQl,
    ids: &[MediaId],
) -> Result<Vec<(MediaId, Option<MediaFormat>)>, SourceError> {
    if ids.is_empty() {
        return Ok(Vec::new());
    }
    let numbers: Vec<u64> = ids.iter().map(|id| id.get()).collect();
    let variables = json!({ "ids": numbers, "perPage": numbers.len() });
    let data = graphql.run(QUERY, variables).await?;
    let response: RawFormatResponse = parse(data, "formats")?;
    Ok(response
        .page
        .media
        .into_iter()
        .map(|entry| (entry.id, entry.format))
        .collect())
}
