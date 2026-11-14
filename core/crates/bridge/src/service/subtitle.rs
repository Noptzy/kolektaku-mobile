use application::ports::MetadataCatalog;
use application::streaming::parse_vtt;
use domain::error::SourceError;
use infrastructure::http::HttpRequest;

use crate::dto::cues::CueDto;
use crate::dto::stream::HeaderDto;
use crate::error::BridgeError;
use crate::state::AppState;

const FORWARDED: [&str; 2] = ["referer", "origin"];

fn secure(address: &str) -> bool {
    address
        .strip_prefix("https://")
        .is_some_and(|rest| rest.split('/').next().is_some_and(|host| !host.is_empty()))
}

pub async fn cues<C: MetadataCatalog>(
    state: &AppState<C>,
    url: &str,
    headers: &[HeaderDto],
) -> Result<Vec<CueDto>, BridgeError> {
    if !secure(url.trim()) {
        return Err(BridgeError::not_found("the subtitle address is not secure"));
    }
    let mut request = HttpRequest::get(url.trim());
    for header in headers {
        let name = header.name.to_lowercase();
        if FORWARDED.contains(&name.as_str()) {
            request = request.with_header(&name, &header.value);
        }
    }
    let response = state.http.send(request).await?;
    match response.status {
        404 => Err(SourceError::NotFound("subtitle".into()).into()),
        status if !(200..300).contains(&status) => {
            Err(SourceError::Unavailable(format!("subtitle returned HTTP {status}")).into())
        }
        _ => Ok(parse_vtt(&response.body).iter().map(Into::into).collect()),
    }
}
