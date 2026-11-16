use crate::dto::follow::UpdateEventDto;
use crate::error::BridgeError;
use crate::service::follow;
use crate::state::global;

pub async fn check_followed_updates() -> Result<Vec<UpdateEventDto>, BridgeError> {
    Ok(follow::check_followed(global()?).await)
}
