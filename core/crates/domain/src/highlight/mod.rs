use serde::{Deserialize, Serialize};

use crate::error::StorageError;
use crate::media::MediaRef;

pub const MAX_QUOTE_CHARS: usize = 1_000;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HighlightInput {
    pub media: MediaRef,
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

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Highlight {
    pub id: i64,
    #[serde(flatten)]
    pub entry: HighlightInput,
    pub created_at_secs: u64,
}

impl HighlightInput {
    pub fn is_storable(&self) -> bool {
        let letters = self.quote.chars().count();
        self.end > self.start
            && letters > 0
            && letters <= MAX_QUOTE_CHARS
            && !self.quote.contains('\n')
            && self.chapter.is_finite()
    }
}

pub trait HighlightStore: Send + Sync {
    fn add(
        &self,
        input: HighlightInput,
        now_secs: u64,
    ) -> impl std::future::Future<Output = Result<i64, StorageError>> + Send;

    fn remove(&self, id: i64)
    -> impl std::future::Future<Output = Result<(), StorageError>> + Send;

    fn for_chapter(
        &self,
        media: &MediaRef,
        chapter: f64,
    ) -> impl std::future::Future<Output = Result<Vec<Highlight>, StorageError>> + Send;

    fn all(&self)
    -> impl std::future::Future<Output = Result<Vec<Highlight>, StorageError>> + Send;
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::media::MediaId;

    fn input(quote: &str, start: u32, end: u32) -> HighlightInput {
        HighlightInput {
            media: MediaRef::catalog(MediaId::new(1).unwrap()),
            title: "Hyouka".into(),
            cover_url: None,
            chapter: 1.0,
            chapter_label: "Vol 1 \u{b7} 1".into(),
            block: 2,
            start,
            end,
            quote: quote.into(),
            language: "en".into(),
        }
    }

    #[test]
    fn a_short_single_paragraph_quote_with_a_range_is_storable() {
        assert!(input("Join the Classics Club.", 0, 23).is_storable());
    }

    #[test]
    fn an_empty_range_an_empty_quote_or_a_line_break_is_not() {
        assert!(!input("x", 3, 3).is_storable());
        assert!(!input("x", 5, 3).is_storable());
        assert!(!input("", 0, 1).is_storable());
        assert!(!input("a\nb", 0, 3).is_storable());
    }

    #[test]
    fn a_quote_over_the_limit_is_not_storable() {
        let long = "x".repeat(MAX_QUOTE_CHARS + 1);
        assert!(!input(&long, 0, 5).is_storable());
        let edge = "x".repeat(MAX_QUOTE_CHARS);
        assert!(input(&edge, 0, 5).is_storable());
    }

    #[test]
    fn a_highlight_round_trips_through_json() {
        let highlight = Highlight {
            id: 4,
            entry: input("Join the Classics Club.", 0, 23),
            created_at_secs: 10,
        };
        let json = serde_json::to_string(&highlight).unwrap();
        assert_eq!(serde_json::from_str::<Highlight>(&json).unwrap(), highlight);
    }
}
