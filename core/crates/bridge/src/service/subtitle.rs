use application::ports::MetadataCatalog;
use application::streaming::{Cue, parse_vtt};
use application::translation::TranslateCues;
use domain::error::SourceError;
use domain::translation::LanguageRoute;
use infrastructure::http::HttpRequest;

use crate::dto::cues::{CueDto, CuePlanDto};
use crate::dto::stream::HeaderDto;
use crate::error::BridgeError;
use crate::state::AppState;

const FORWARDED: [&str; 2] = ["referer", "origin"];

fn secure(address: &str) -> bool {
    address
        .strip_prefix("https://")
        .is_some_and(|rest| rest.split('/').next().is_some_and(|host| !host.is_empty()))
}

async fn download<C: MetadataCatalog>(
    state: &AppState<C>,
    url: &str,
    headers: &[HeaderDto],
) -> Result<Vec<Cue>, BridgeError> {
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
        _ => Ok(parse_vtt(&response.body)),
    }
}

pub async fn cues<C: MetadataCatalog>(
    state: &AppState<C>,
    url: &str,
    headers: &[HeaderDto],
    language: Option<&str>,
    position_ms: u64,
    translate: bool,
) -> Result<CuePlanDto, BridgeError> {
    let original = download(state, url, headers).await?;
    if !translate {
        return Ok(CuePlanDto::plain(&original));
    }
    let target = state.settings.get().translation;
    let Some(route) = LanguageRoute::new(language, target) else {
        return Ok(CuePlanDto::plain(&original));
    };
    if route.needs_no_translation() || original.is_empty() {
        return Ok(CuePlanDto::plain(&original));
    }
    let outcome = TranslateCues::new(state.translator.clone())
        .execute(original, &route, position_ms)
        .await;
    Ok(CuePlanDto {
        cues: outcome.cues.iter().map(CueDto::from).collect(),
        translated: outcome.translated,
        failed: outcome.failed,
        retry_at_secs: if outcome.failed {
            state.translation_health.paused_until()
        } else {
            None
        },
    })
}
