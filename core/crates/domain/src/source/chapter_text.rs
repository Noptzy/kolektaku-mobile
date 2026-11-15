use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "type", content = "value", rename_all = "snake_case")]
pub enum TextBlock {
    Paragraph(String),
    Image(String),
}

impl TextBlock {
    pub fn paragraph_text(&self) -> Option<&str> {
        match self {
            Self::Paragraph(text) => Some(text),
            Self::Image(_) => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ChapterText {
    pub blocks: Vec<TextBlock>,
    pub language: String,
}

impl ChapterText {
    pub fn new(language: impl Into<String>, blocks: Vec<TextBlock>) -> Self {
        Self {
            blocks,
            language: language.into(),
        }
    }

    pub fn from_paragraphs(
        language: impl Into<String>,
        paragraphs: impl IntoIterator<Item = String>,
    ) -> Self {
        let blocks = paragraphs.into_iter().map(TextBlock::Paragraph).collect();
        Self::new(language, blocks)
    }

    pub fn is_empty(&self) -> bool {
        self.blocks.is_empty()
    }

    pub fn paragraphs(&self) -> impl Iterator<Item = &str> {
        self.blocks.iter().filter_map(TextBlock::paragraph_text)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mixed() -> ChapterText {
        ChapterText::new(
            "id",
            vec![
                TextBlock::Paragraph("Satu".into()),
                TextBlock::Image("https://img.test/a.jpg".into()),
                TextBlock::Paragraph("Dua".into()),
            ],
        )
    }

    #[test]
    fn from_paragraphs_keeps_order_and_language() {
        let text = ChapterText::from_paragraphs("en", ["a".to_string(), "b".to_string()]);
        assert_eq!(text.language, "en");
        let all: Vec<&str> = text.paragraphs().collect();
        assert_eq!(all, vec!["a", "b"]);
    }

    #[test]
    fn paragraphs_skip_illustrations() {
        let text = mixed();
        let all: Vec<&str> = text.paragraphs().collect();
        assert_eq!(all, vec!["Satu", "Dua"]);
        assert_eq!(text.blocks.len(), 3);
    }

    #[test]
    fn a_text_without_blocks_is_empty() {
        assert!(ChapterText::new("id", Vec::new()).is_empty());
        assert!(!mixed().is_empty());
    }

    #[test]
    fn json_names_each_block_and_round_trips() {
        let json = serde_json::to_string(&mixed()).unwrap();
        assert!(json.contains("\"type\":\"paragraph\""));
        assert!(json.contains("\"type\":\"image\""));
        assert_eq!(serde_json::from_str::<ChapterText>(&json).unwrap(), mixed());
    }
}
