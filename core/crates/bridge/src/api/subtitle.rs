use crate::dto::cues::CuePlanDto;
use crate::dto::stream::HeaderDto;
use crate::error::BridgeError;
use crate::service::subtitle;
use crate::state::global;

pub async fn fetch_cues(
    url: String,
    headers: Vec<HeaderDto>,
    language: Option<String>,
    position_ms: u64,
    translate: bool,
) -> Result<CuePlanDto, BridgeError> {
    subtitle::cues(
        global()?,
        &url,
        &headers,
        language.as_deref(),
        position_ms,
        translate,
    )
    .await
}
