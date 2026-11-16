use std::sync::Arc;

use domain::source::{ChapterText, TextBlock};
use domain::translation::LanguageRoute;

use super::translate_lines::TranslateLines;
use crate::ports::Translator;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BlockTranslation {
    pub blocks: Vec<TextBlock>,
    pub translated: bool,
    pub failed: bool,
}

pub struct TranslateBlocks {
    lines: TranslateLines,
}

impl TranslateBlocks {
    pub fn new(translator: Arc<dyn Translator>) -> Self {
        Self {
            lines: TranslateLines::new(translator),
        }
    }

    pub async fn execute(&self, text: &ChapterText, route: &LanguageRoute) -> BlockTranslation {
        let paragraphs: Vec<String> = text.paragraphs().map(str::to_string).collect();
        let outcome = self.lines.execute(paragraphs, route, 0).await;
        if !outcome.translated {
            return BlockTranslation {
                blocks: text.blocks.clone(),
                translated: false,
                failed: outcome.failed,
            };
        }
        let mut translated = outcome.lines.into_iter();
        let blocks = text
            .blocks
            .iter()
            .map(|block| match block {
                TextBlock::Paragraph(original) => {
                    TextBlock::Paragraph(translated.next().unwrap_or_else(|| original.clone()))
                }
                TextBlock::Image(url) => TextBlock::Image(url.clone()),
            })
            .collect();
        BlockTranslation {
            blocks,
            translated: true,
            failed: outcome.failed,
        }
    }
}
