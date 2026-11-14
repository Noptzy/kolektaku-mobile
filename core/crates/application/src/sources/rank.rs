use std::collections::HashMap;

use domain::source::{SourceId, SourceLink};

use super::SourceHealth;

pub fn rank_links(
    mut links: Vec<SourceLink>,
    priorities: &HashMap<SourceId, u8>,
    health: &SourceHealth,
    preferred: Option<&SourceId>,
) -> Vec<SourceLink> {
    links.sort_by_key(|link| {
        (
            std::cmp::Reverse(link.manual),
            std::cmp::Reverse(link.confidence.is_automatic()),
            std::cmp::Reverse(preferred == Some(&link.source)),
            std::cmp::Reverse(link.unit_count.unwrap_or(0)),
            priorities.get(&link.source).copied().unwrap_or(u8::MAX),
            health.recent_failures(&link.source),
        )
    });
    links
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use domain::matching::Confidence;
    use domain::source::ItemId;

    use super::*;
    use crate::testing::FakeClock;

    fn link(source: &str, confidence: f32, units: Option<u32>, manual: bool) -> SourceLink {
        let mut link = SourceLink::matched(
            SourceId::new(source),
            ItemId::new("x"),
            Confidence::new(confidence),
            0,
        )
        .with_unit_count(units);
        link.manual = manual;
        link
    }

    fn order(links: Vec<SourceLink>, priorities: &[(&str, u8)]) -> Vec<String> {
        order_preferring(links, priorities, None)
    }

    fn order_preferring(
        links: Vec<SourceLink>,
        priorities: &[(&str, u8)],
        preferred: Option<&str>,
    ) -> Vec<String> {
        let preferred = preferred.map(SourceId::new);
        let table: HashMap<SourceId, u8> = priorities
            .iter()
            .map(|(id, priority)| (SourceId::new(*id), *priority))
            .collect();
        let health = SourceHealth::new(Arc::new(FakeClock::at(0)));
        rank_links(links, &table, &health, preferred.as_ref())
            .iter()
            .map(|link| link.source.to_string())
            .collect()
    }

    #[test]
    fn a_manual_choice_beats_everything() {
        let links = vec![link("a", 1.0, Some(99), false), link("b", 0.5, None, true)];
        assert_eq!(order(links, &[("a", 1), ("b", 9)]), vec!["b", "a"]);
    }

    #[test]
    fn an_automatic_confidence_beats_a_doubtful_one() {
        let links = vec![
            link("a", 0.7, Some(99), false),
            link("b", 0.9, Some(1), false),
        ];
        assert_eq!(order(links, &[("a", 1), ("b", 9)]), vec!["b", "a"]);
    }

    #[test]
    fn more_episodes_beat_a_better_priority() {
        let links = vec![
            link("a", 0.9, Some(12), false),
            link("b", 0.9, Some(24), false),
        ];
        assert_eq!(order(links, &[("a", 1), ("b", 9)]), vec!["b", "a"]);
    }

    #[test]
    fn priority_breaks_a_complete_tie_and_a_smaller_number_wins() {
        let links = vec![
            link("b", 0.9, Some(12), false),
            link("a", 0.9, Some(12), false),
        ];
        assert_eq!(order(links, &[("a", 1), ("b", 9)]), vec!["a", "b"]);
    }

    #[test]
    fn the_preferred_source_beats_more_episodes_and_priority() {
        let links = vec![
            link("a", 0.9, Some(24), false),
            link("b", 0.9, Some(8), false),
        ];
        assert_eq!(
            order_preferring(links, &[("a", 1), ("b", 9)], Some("b")),
            vec!["b", "a"]
        );
    }

    #[test]
    fn the_preference_never_beats_a_manual_choice_or_a_doubtful_match() {
        let manual = vec![link("a", 0.5, None, true), link("b", 0.9, Some(1), false)];
        assert_eq!(
            order_preferring(manual, &[("a", 1), ("b", 2)], Some("b")),
            vec!["a", "b"]
        );
        let doubtful = vec![
            link("a", 0.95, Some(3), false),
            link("b", 0.7, Some(9), false),
        ];
        assert_eq!(
            order_preferring(doubtful, &[("a", 1), ("b", 2)], Some("b")),
            vec!["a", "b"]
        );
    }

    #[test]
    fn a_preference_for_a_source_without_a_link_changes_nothing() {
        let links = vec![
            link("a", 0.9, Some(24), false),
            link("b", 0.9, Some(8), false),
        ];
        assert_eq!(
            order_preferring(links, &[("a", 1), ("b", 9)], Some("ghost")),
            vec!["a", "b"]
        );
    }

    #[test]
    fn health_breaks_the_last_tie() {
        let clock = Arc::new(FakeClock::at(0));
        let health = SourceHealth::new(clock);
        let flaky = SourceId::new("flaky");
        health.record_failure(&flaky, &domain::error::SourceError::Network("x".into()));
        let links = vec![
            link("flaky", 0.9, Some(12), false),
            link("solid", 0.9, Some(12), false),
        ];
        let ranked = rank_links(links, &HashMap::new(), &health, None);
        assert_eq!(ranked[0].source.as_str(), "solid");
    }
}
