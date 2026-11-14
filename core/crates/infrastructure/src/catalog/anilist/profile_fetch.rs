use domain::error::SourceError;
use domain::media::{Profile, ProfileKind, ProfileSummary};
use serde_json::json;

use super::catalog::parse;
use super::graphql::GraphQl;
use super::mapper::{map_people, map_profile, map_studio};
use super::people_queries::search_profiles_query;
use super::profile_queries::profile_query;
use super::schema::{RawPeopleResponse, RawProfileResponse, RawStudioResponse};

pub(super) async fn fetch_profile(
    graphql: &GraphQl,
    kind: ProfileKind,
    id: u64,
) -> Result<Profile, SourceError> {
    let data = graphql
        .run(&profile_query(kind), json!({ "id": id }))
        .await?;
    if kind == ProfileKind::Studio {
        let response: RawStudioResponse = parse(data, "studio")?;
        return Ok(map_studio(response.studio));
    }
    let response: RawProfileResponse = parse(data, "profile")?;
    Ok(map_profile(response.profile))
}

pub(super) async fn fetch_people(
    graphql: &GraphQl,
    kind: ProfileKind,
    query: &str,
) -> Result<Vec<ProfileSummary>, SourceError> {
    let search = query.trim();
    if search.is_empty() {
        return Ok(Vec::new());
    }
    let data = graphql
        .run(search_profiles_query(kind), json!({ "search": search }))
        .await?;
    let response: RawPeopleResponse = parse(data, "profiles")?;
    Ok(map_people(kind, response.page))
}
