use domain::source::{SourceId, SourceLink};

use super::SourceHealth;

pub fn next_source_for<'a>(
    ranked: &'a [SourceLink],
    failed: &[SourceId],
    episode: f64,
    health: &SourceHealth,
) -> Option<&'a SourceLink> {
    ranked.iter().find(|link| {
        let has_the_episode = link
            .unit_count
            .is_none_or(|count| episode <= f64::from(count));
        has_the_episode && !failed.contains(&link.source) && !health.is_skipped(&link.source)
    })
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use domain::error::SourceError;
    use domain::matching::Confidence;
    use domain::source::ItemId;

    use super::*;
    use crate::testing::FakeClock;

    fn link(source: &str, units: Option<u32>) -> SourceLink {
        SourceLink::matched(
            SourceId::new(source),
            ItemId::new("x"),
            Confidence::new(0.9),
            0,
        )
        .with_unit_count(units)
    }

    fn health() -> SourceHealth {
        SourceHealth::new(Arc::new(FakeClock::at(0)))
    }

    #[test]
    fn the_first_ranked_site_that_has_not_failed_is_next() {
        let ranked = vec![
            link("a", Some(12)),
            link("b", Some(12)),
            link("c", Some(12)),
        ];
        let next = next_source_for(&ranked, &[SourceId::new("a")], 5.0, &health());
        assert_eq!(next.map(|link| link.source.as_str()), Some("b"));
    }

    #[test]
    fn a_site_whose_count_is_too_small_for_the_episode_is_passed_over() {
        let ranked = vec![link("a", Some(12)), link("b", Some(4)), link("c", None)];
        let next = next_source_for(&ranked, &[SourceId::new("a")], 6.0, &health());
        assert_eq!(next.map(|link| link.source.as_str()), Some("c"));
        let early = next_source_for(&ranked, &[SourceId::new("a")], 4.0, &health());
        assert_eq!(early.map(|link| link.source.as_str()), Some("b"));
    }

    #[test]
    fn a_skipped_site_is_passed_over() {
        let ranked = vec![link("a", None), link("b", None)];
        let health = health();
        for _ in 0..3 {
            health.record_failure(&SourceId::new("a"), &SourceError::Network("x".into()));
        }
        assert_eq!(
            next_source_for(&ranked, &[], 1.0, &health).map(|link| link.source.as_str()),
            Some("b")
        );
    }

    #[test]
    fn nothing_is_next_when_every_site_has_failed() {
        let ranked = vec![link("a", None)];
        assert!(next_source_for(&ranked, &[SourceId::new("a")], 1.0, &health()).is_none());
        assert!(next_source_for(&[], &[], 1.0, &health()).is_none());
    }

    #[test]
    fn fractional_episodes_fit_inside_the_count() {
        let ranked = vec![link("a", Some(12))];
        assert!(next_source_for(&ranked, &[], 11.5, &health()).is_some());
        assert!(next_source_for(&ranked, &[], 12.5, &health()).is_none());
    }
}
