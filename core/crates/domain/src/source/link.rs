use serde::{Deserialize, Serialize};

use super::{ItemId, LinkVariant, SourceId};
use crate::matching::Confidence;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct SourceLink {
    pub source: SourceId,
    pub item: ItemId,
    pub confidence: Confidence,
    pub unit_count: Option<u32>,
    pub checked_at_secs: u64,
    pub manual: bool,
    #[serde(default)]
    pub variants: Vec<LinkVariant>,
    #[serde(default)]
    pub matcher_version: u32,
    #[serde(default)]
    pub title: Option<String>,
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
            variants: Vec::new(),
            matcher_version: 0,
            title: None,
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
            variants: Vec::new(),
            matcher_version: 0,
            title: None,
        }
    }

    pub fn with_unit_count(mut self, unit_count: Option<u32>) -> Self {
        self.unit_count = unit_count;
        self
    }

    pub fn with_variants(mut self, variants: Vec<LinkVariant>) -> Self {
        self.variants = variants;
        self
    }

    pub fn with_title(mut self, title: impl Into<String>) -> Self {
        self.title = Some(title.into());
        self
    }

    pub fn with_matcher_version(mut self, version: u32) -> Self {
        self.matcher_version = version;
        self
    }

    pub fn variant_for(&self, audio: &str) -> Option<&LinkVariant> {
        self.variants.iter().find(|variant| variant.audio == audio)
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
    fn a_link_saved_before_variants_existed_still_reads() {
        let json = r#"{"source":"a","item":"1","confidence":0.9,"unit_count":null,"checked_at_secs":5,"manual":false}"#;
        let link: SourceLink = serde_json::from_str(json).unwrap();
        assert!(link.variants.is_empty());
        assert_eq!(link.matcher_version, 0);
        assert_eq!(link.title, None);
    }

    #[test]
    fn the_site_title_is_kept_for_the_confirmation_prompt() {
        let link = SourceLink::matched(
            SourceId::new("a"),
            ItemId::new("1"),
            Confidence::new(0.7),
            1,
        )
        .with_title("Kimetsu no Yaiba (TV)");
        assert_eq!(link.title.as_deref(), Some("Kimetsu no Yaiba (TV)"));
    }

    #[test]
    fn variants_and_matcher_version_are_kept() {
        let link = SourceLink::matched(
            SourceId::new("a"),
            ItemId::new("1"),
            Confidence::new(0.9),
            1,
        )
        .with_variants(vec![LinkVariant::new(ItemId::new("2"), "Dub Indonesia")])
        .with_matcher_version(2);
        assert_eq!(link.matcher_version, 2);
        assert_eq!(
            link.variant_for("Dub Indonesia").unwrap().item,
            ItemId::new("2")
        );
        assert!(link.variant_for("Dub").is_none());
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
