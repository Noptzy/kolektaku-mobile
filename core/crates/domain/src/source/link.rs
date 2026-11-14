use serde::{Deserialize, Serialize};

use super::{ItemId, SourceId};
use crate::matching::Confidence;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SourceLink {
    pub source: SourceId,
    pub item: ItemId,
    pub confidence: Confidence,
    pub unit_count: Option<u32>,
    pub checked_at_secs: u64,
    pub manual: bool,
}

impl SourceLink {
    pub fn matched(
        source: SourceId,
        item: ItemId,
        confidence: Confidence,
        checked_at_secs: u64,
    ) -> Self {
        Self {
            source,
            item,
            confidence,
            unit_count: None,
            checked_at_secs,
            manual: false,
        }
    }

    pub fn chosen_by_user(source: SourceId, item: ItemId, checked_at_secs: u64) -> Self {
        Self {
            source,
            item,
            confidence: Confidence::new(1.0),
            unit_count: None,
            checked_at_secs,
            manual: true,
        }
    }

    pub fn with_unit_count(mut self, unit_count: Option<u32>) -> Self {
        self.unit_count = unit_count;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn matched_link_is_not_manual() {
        let link = SourceLink::matched(
            SourceId::new("a"),
            ItemId::new("1"),
            Confidence::new(0.9),
            100,
        );
        assert!(!link.manual);
        assert_eq!(link.unit_count, None);
    }

    #[test]
    fn user_choice_is_manual_with_full_confidence() {
        let link = SourceLink::chosen_by_user(SourceId::new("a"), ItemId::new("1"), 100);
        assert!(link.manual);
        assert_eq!(link.confidence, Confidence::new(1.0));
    }

    #[test]
    fn with_unit_count_sets_the_count() {
        let link = SourceLink::matched(
            SourceId::new("a"),
            ItemId::new("1"),
            Confidence::new(0.9),
            1,
        )
        .with_unit_count(Some(12));
        assert_eq!(link.unit_count, Some(12));
    }

    #[test]
    fn survives_a_json_round_trip() {
        let link = SourceLink::matched(
            SourceId::new("a"),
            ItemId::new("1"),
            Confidence::new(0.75),
            5,
        )
        .with_unit_count(Some(3));
        let json = serde_json::to_string(&link).unwrap();
        assert_eq!(serde_json::from_str::<SourceLink>(&json).unwrap(), link);
    }
}
