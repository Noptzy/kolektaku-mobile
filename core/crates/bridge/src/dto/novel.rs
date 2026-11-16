use application::reading::NovelChapterView;
use domain::source::TextBlock;

use super::sources::UnitDto;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NovelBlockDto {
    pub is_image: bool,
    pub text: String,
}

impl From<&TextBlock> for NovelBlockDto {
    fn from(block: &TextBlock) -> Self {
        match block {
            TextBlock::Paragraph(text) => Self {
                is_image: false,
                text: text.clone(),
            },
            TextBlock::Image(url) => Self {
                is_image: true,
                text: url.clone(),
            },
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct NovelChapterDto {
    pub source: String,
    pub item: String,
    pub unit: UnitDto,
    pub language: String,
    pub blocks: Vec<NovelBlockDto>,
    pub translated_language: Option<String>,
    pub translated_blocks: Vec<NovelBlockDto>,
    pub translation_failed: bool,
    pub retry_at_secs: Option<u64>,
    pub switched_from: Option<String>,
}

impl NovelChapterDto {
    pub fn from_view(view: &NovelChapterView, retry_at_secs: Option<u64>) -> Self {
        let translation = view.translation.as_ref();
        Self {
            source: view.source.to_string(),
            item: view.item.to_string(),
            unit: (&view.unit).into(),
            language: view.text.language.clone(),
            blocks: view.text.blocks.iter().map(Into::into).collect(),
            translated_language: translation.map(|found| found.language.clone()),
            translated_blocks: translation
                .map(|found| found.blocks.iter().map(Into::into).collect())
                .unwrap_or_default(),
            translation_failed: view.translation_failed,
            retry_at_secs: if view.translation_failed {
                retry_at_secs
            } else {
                None
            },
            switched_from: view.switched_from.as_ref().map(ToString::to_string),
        }
    }
}
