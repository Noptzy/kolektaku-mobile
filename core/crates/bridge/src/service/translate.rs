use application::ports::MetadataCatalog;
use application::translation::TranslateLines;
use domain::translation::LanguageRoute;

use crate::dto::translate::TextTranslationDto;
use crate::state::AppState;

pub async fn texts<C: MetadataCatalog>(
    state: &AppState<C>,
    texts: Vec<String>,
) -> TextTranslationDto {
    let target = state.settings.get().translation;
    let Some(route) = LanguageRoute::detecting(target) else {
        return untouched(texts);
    };
    let outcome = TranslateLines::new(state.translator.clone())
        .execute(texts, &route, 0)
        .await;
    TextTranslationDto {
        texts: outcome.lines,
        translated: outcome.translated,
        failed: outcome.failed,
    }
}

pub fn paused_until<C: MetadataCatalog>(state: &AppState<C>) -> Option<u64> {
    state.translation_health.paused_until()
}

fn untouched(texts: Vec<String>) -> TextTranslationDto {
    TextTranslationDto {
        texts,
        translated: false,
        failed: false,
    }
}
