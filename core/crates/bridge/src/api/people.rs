use crate::dto::profile::{ProfileDto, ProfileKindDto};
use crate::dto::profile_summary::ProfileSummaryDto;
use crate::error::BridgeError;
use crate::service::people;
use crate::state::global;

pub async fn profile(kind: ProfileKindDto, id: u64) -> Result<ProfileDto, BridgeError> {
    people::profile(global()?, kind, id).await
}

pub async fn search_people(
    kind: ProfileKindDto,
    query: String,
) -> Result<Vec<ProfileSummaryDto>, BridgeError> {
    people::search(global()?, kind, &query).await
}
