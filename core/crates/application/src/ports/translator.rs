use domain::error::SourceError;
use domain::translation::{LanguageRoute, TranslationReply};

use super::BoxFuture;

pub trait Translator: Send + Sync {
    fn translate(
        &self,
        lines: Vec<String>,
        route: LanguageRoute,
    ) -> BoxFuture<'_, Result<TranslationReply, SourceError>>;
}
