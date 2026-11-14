use crate::dto::cues::CueDto;
use crate::dto::stream::HeaderDto;
use crate::error::BridgeError;
use crate::service::subtitle;
use crate::state::global;

pub async fn fetch_cues(url: String, headers: Vec<HeaderDto>) -> Result<Vec<CueDto>, BridgeError> {
    subtitle::cues(global()?, &url, &headers).await
}
