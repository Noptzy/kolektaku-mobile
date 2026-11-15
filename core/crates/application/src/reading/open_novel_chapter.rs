use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaRef;
use domain::settings::TranslationLanguage;
use domain::source::{ChapterText, ItemId, SourceId, SourceLinkStore, TextBlock, Unit};
use domain::translation::LanguageRoute;

use crate::ports::Translator;
use crate::sources::{SourceDirectory, SourceHealth, candidate_links, find_unit, first_working};
use crate::translation::TranslateBlocks;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NovelTranslation {
    pub language: String,
    pub blocks: Vec<TextBlock>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct NovelChapterView {
    pub source: SourceId,
    pub item: ItemId,
    pub unit: Unit,
    pub text: ChapterText,
    pub translation: Option<NovelTranslation>,
    pub translation_failed: bool,
    pub switched_from: Option<SourceId>,
}

pub struct OpenNovelChapter<S: SourceLinkStore> {
    links: Arc<S>,
    directory: Arc<SourceDirectory>,
    health: Arc<SourceHealth>,
    translate: TranslateBlocks,
}

impl<S: SourceLinkStore> OpenNovelChapter<S> {
    pub fn new(
        links: Arc<S>,
        directory: Arc<SourceDirectory>,
        health: Arc<SourceHealth>,
        translator: Arc<dyn Translator>,
    ) -> Self {
        Self {
            links,
            directory,
            health,
            translate: TranslateBlocks::new(translator),
        }
    }

    pub async fn execute(
        &self,
        reference: &MediaRef,
        chapter: f64,
        preferred: Option<&SourceId>,
        exclude: &[SourceId],
        target: TranslationLanguage,
    ) -> Result<NovelChapterView, SourceError> {
        let links = candidate_links(
            self.links.as_ref(),
            &self.directory,
            &self.health,
            reference,
        )
        .await;
        let directory = &self.directory;
        let working = first_working(links, &self.health, preferred, exclude, |link| async move {
            let units = directory
                .get(&link.source)?
                .units(link.item.clone())
                .await?;
            let unit = find_unit(&units, chapter)
                .cloned()
                .ok_or_else(|| SourceError::NotFound(format!("chapter {chapter}")))?;
            let text = directory
                .texts(&link.source)?
                .chapter_text(unit.id.clone())
                .await?;
            Ok((unit, text))
        })
        .await?;
        let (unit, text) = working.value;
        let (translation, translation_failed) = self.translated(&text, target).await;
        Ok(NovelChapterView {
            source: working.link.source,
            item: working.link.item,
            unit,
            text,
            translation,
            translation_failed,
            switched_from: working.switched_from,
        })
    }

    async fn translated(
        &self,
        text: &ChapterText,
        target: TranslationLanguage,
    ) -> (Option<NovelTranslation>, bool) {
        let Some(route) = LanguageRoute::new(Some(&text.language), target) else {
            return (None, false);
        };
        if route.needs_no_translation() || text.is_empty() {
            return (None, false);
        }
        let outcome = self.translate.execute(text, &route).await;
        let translation = outcome.translated.then(|| NovelTranslation {
            language: route.target_code().to_string(),
            blocks: outcome.blocks,
        });
        (translation, outcome.failed)
    }
}
