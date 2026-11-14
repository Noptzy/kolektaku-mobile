use domain::error::SourceError;
use domain::source::{SourceId, SourceLink};

use super::find_link::Found;

pub const REVALIDATE_AFTER_SECS: u64 = 14 * 24 * 60 * 60;

pub fn is_fresh(link: &SourceLink, now_secs: u64) -> bool {
    link.manual
        || (link.confidence.is_automatic()
            && now_secs.saturating_sub(link.checked_at_secs) < REVALIDATE_AFTER_SECS)
}

pub struct Answer {
    pub source: SourceId,
    pub result: Result<Option<Found>, SourceError>,
}

pub struct Merged {
    pub links: Vec<SourceLink>,
    pub answered: bool,
    pub first_error: Option<SourceError>,
}

pub fn merge_answers(stored: &[SourceLink], answers: Vec<Answer>) -> Merged {
    let mut links: Vec<SourceLink> = stored
        .iter()
        .filter(|link| link.manual || answers.iter().all(|answer| answer.source != link.source))
        .cloned()
        .collect();
    let mut answered = false;
    let mut first_error = None;
    for answer in answers {
        match answer.result {
            Ok(found) => {
                answered = true;
                links.extend(found.map(|item| item.link));
            }
            Err(error) => {
                first_error = first_error.or(Some(error));
                links.extend(
                    stored
                        .iter()
                        .filter(|link| link.source == answer.source && !link.manual)
                        .cloned(),
                );
            }
        }
    }
    Merged {
        links,
        answered,
        first_error,
    }
}

#[cfg(test)]
mod tests {
    use domain::matching::Confidence;
    use domain::source::ItemId;

    use super::*;

    fn link(
        source: &str,
        item: &str,
        confidence: f32,
        checked_at: u64,
        manual: bool,
    ) -> SourceLink {
        let mut link = SourceLink::matched(
            SourceId::new(source),
            ItemId::new(item),
            Confidence::new(confidence),
            checked_at,
        );
        link.manual = manual;
        link
    }

    fn found(source: &str, item: &str) -> Result<Option<Found>, SourceError> {
        Ok(Some(Found {
            link: link(source, item, 0.9, 100, false),
            needs_hint: false,
        }))
    }

    #[test]
    fn a_link_is_fresh_when_manual_or_recent_and_trusted() {
        assert!(is_fresh(&link("a", "1", 0.5, 0, true), u64::MAX / 2));
        assert!(is_fresh(
            &link("a", "1", 0.9, 1_000, false),
            1_000 + REVALIDATE_AFTER_SECS - 1
        ));
        assert!(!is_fresh(
            &link("a", "1", 0.9, 1_000, false),
            1_000 + REVALIDATE_AFTER_SECS
        ));
        assert!(!is_fresh(&link("a", "1", 0.84, 1_000, false), 1_001));
    }

    #[test]
    fn a_new_answer_replaces_the_stored_automatic_link_of_that_site() {
        let stored = vec![link("a", "old", 0.9, 1, false)];
        let merged = merge_answers(
            &stored,
            vec![Answer {
                source: SourceId::new("a"),
                result: found("a", "new"),
            }],
        );
        assert_eq!(merged.links.len(), 1);
        assert_eq!(merged.links[0].item.as_str(), "new");
        assert!(merged.answered && merged.first_error.is_none());
    }

    #[test]
    fn a_manual_link_always_survives_even_when_the_site_answers_differently() {
        let stored = vec![link("a", "mine", 1.0, 1, true)];
        let merged = merge_answers(
            &stored,
            vec![Answer {
                source: SourceId::new("a"),
                result: found("a", "auto"),
            }],
        );
        let items: Vec<&str> = merged.links.iter().map(|link| link.item.as_str()).collect();
        assert!(items.contains(&"mine"));
    }

    #[test]
    fn a_failing_site_keeps_what_was_stored_for_it_and_reports_the_error() {
        let stored = vec![link("a", "old", 0.9, 1, false)];
        let failing = Answer {
            source: SourceId::new("a"),
            result: Err(SourceError::Unavailable("down".into())),
        };
        let merged = merge_answers(&stored, vec![failing]);
        assert_eq!(merged.links.len(), 1);
        assert!(!merged.answered);
        assert!(matches!(
            merged.first_error,
            Some(SourceError::Unavailable(_))
        ));
    }

    #[test]
    fn a_site_that_now_finds_nothing_loses_its_old_automatic_link() {
        let stored = vec![link("a", "old", 0.9, 1, false)];
        let merged = merge_answers(
            &stored,
            vec![Answer {
                source: SourceId::new("a"),
                result: Ok(None),
            }],
        );
        assert!(merged.links.is_empty());
        assert!(merged.answered);
    }

    #[test]
    fn sites_that_were_not_asked_keep_their_stored_links() {
        let stored = vec![link("b", "kept", 0.9, 1, false)];
        let merged = merge_answers(
            &stored,
            vec![Answer {
                source: SourceId::new("a"),
                result: found("a", "new"),
            }],
        );
        assert_eq!(merged.links.len(), 2);
    }
}
