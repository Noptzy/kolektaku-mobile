use application::ports::MetadataCatalog;

use crate::dto::profile::{ProfileDto, ProfileKindDto};
use crate::dto::profile_summary::ProfileSummaryDto;
use crate::error::BridgeError;
use crate::state::AppState;

pub async fn profile<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: ProfileKindDto,
    id: u64,
) -> Result<ProfileDto, BridgeError> {
    let found = state.catalog.profile(kind.into(), id).await?;
    Ok(ProfileDto::from(&found))
}

pub async fn search<C: MetadataCatalog>(
    state: &AppState<C>,
    kind: ProfileKindDto,
    query: &str,
) -> Result<Vec<ProfileSummaryDto>, BridgeError> {
    let found = state.catalog.search_profiles(kind.into(), query).await?;
    Ok(found.iter().map(Into::into).collect())
}
