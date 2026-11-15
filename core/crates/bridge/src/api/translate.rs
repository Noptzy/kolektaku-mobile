use crate::dto::translate::TextTranslationDto;
use crate::error::BridgeError;
use crate::service::translate;
use crate::state::global;

pub async fn translate_texts(texts: Vec<String>) -> Result<TextTranslationDto, BridgeError> {
    Ok(translate::texts(global()?, texts).await)
}

pub async fn translation_paused_until() -> Result<Option<u64>, BridgeError> {
    Ok(translate::paused_until(global()?))
}
