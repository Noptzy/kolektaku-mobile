use domain::highlight::{Highlight, HighlightInput};

use super::media::{MediaKindDto, MediaRefDto};
use crate::error::BridgeError;

#[derive(Debug, Clone, PartialEq)]
pub struct HighlightInputDto {
    pub reference: MediaRefDto,
    pub title: String,
    pub cover_url: Option<String>,
    pub chapter: f64,
    pub chapter_label: String,
    pub block: u32,
    pub start: u32,
    pub end: u32,
    pub quote: String,
    pub language: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct HighlightDto {
    pub id: i64,
    pub reference: MediaRefDto,
    pub kind: MediaKindDto,
    pub title: String,
    pub cover_url: Option<String>,
    pub chapter: f64,
    pub chapter_label: String,
    pub block: u32,
    pub start: u32,
    pub end: u32,
    pub quote: String,
    pub language: String,
    pub created_at_secs: u64,
}

impl HighlightInputDto {
    pub fn to_domain(&self) -> Result<HighlightInput, BridgeError> {
        Ok(HighlightInput {
            media: self.reference.require()?,
            title: self.title.clone(),
            cover_url: self.cover_url.clone(),
            chapter: self.chapter,
            chapter_label: self.chapter_label.clone(),
            block: self.block,
            start: self.start,
            end: self.end,
            quote: self.quote.clone(),
            language: self.language.clone(),
        })
    }
}

impl From<&Highlight> for HighlightDto {
    fn from(found: &Highlight) -> Self {
        let entry = &found.entry;
        Self {
            id: found.id,
            reference: (&entry.media).into(),
            kind: MediaKindDto::Novel,
            title: entry.title.clone(),
            cover_url: entry.cover_url.clone(),
            chapter: entry.chapter,
            chapter_label: entry.chapter_label.clone(),
            block: entry.block,
            start: entry.start,
            end: entry.end,
            quote: entry.quote.clone(),
            language: entry.language.clone(),
            created_at_secs: found.created_at_secs,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::dto::media::MediaRefKind;

    fn input() -> HighlightInputDto {
        HighlightInputDto {
            reference: MediaRefDto {
                kind: MediaRefKind::Catalog,
                id: 9,
                source: String::new(),
                item: String::new(),
            },
            title: "Hyouka".into(),
            cover_url: None,
            chapter: 1.0,
            chapter_label: "Chapter 1".into(),
            block: 3,
            start: 0,
            end: 5,
            quote: "quote".into(),
            language: "en".into(),
        }
    }

    #[test]
    fn an_input_becomes_a_domain_input_and_a_stored_one_a_dto() {
        let domain = input().to_domain().unwrap();
        assert_eq!(domain.block, 3);
        let stored = Highlight {
            id: 5,
            entry: domain,
            created_at_secs: 9,
        };
        let dto = HighlightDto::from(&stored);
        assert_eq!((dto.id, dto.block, dto.created_at_secs), (5, 3, 9));
        assert_eq!(dto.reference, input().reference);
    }

    #[test]
    fn a_bad_reference_is_refused() {
        let mut bad = input();
        bad.reference.id = 0;
        assert!(bad.to_domain().is_err());
    }
}
