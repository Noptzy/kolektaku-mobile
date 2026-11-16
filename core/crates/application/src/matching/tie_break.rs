use domain::media::MediaStatus;

use super::audio_variant::audio_variant_of;
use super::target::{CandidateFacts, MatchTarget};

pub type TieRank = (bool, bool, bool);

fn is_uncensored(title: &str) -> bool {
    let lowered = title.to_lowercase();
    lowered.contains("uncensored") || lowered.contains("(uncen)")
}

fn unit_count_differs(target: &MatchTarget, facts: &CandidateFacts) -> bool {
    let running = target.status == Some(MediaStatus::Releasing);
    match target.unit_count {
        Some(wanted) if !running => facts.unit_count != Some(wanted),
        _ => false,
    }
}

pub fn tie_rank(target: &MatchTarget, facts: &CandidateFacts) -> TieRank {
    let title = facts.titles.first().map_or("", String::as_str);
    (
        audio_variant_of(title).is_some(),
        is_uncensored(title),
        unit_count_differs(target, facts),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    fn target(units: Option<u32>, status: MediaStatus) -> MatchTarget {
        MatchTarget {
            titles: vec!["Show".into()],
            format: None,
            year: None,
            unit_count: units,
            status: Some(status),
        }
    }

    fn facts(title: &str, units: Option<u32>) -> CandidateFacts {
        CandidateFacts {
            titles: vec![title.into()],
            type_text: None,
            year: None,
            unit_count: units,
        }
    }

    #[test]
    fn a_plain_entry_ranks_before_a_dub_and_an_uncensored_cut() {
        let wanted = target(Some(12), MediaStatus::Finished);
        let plain = tie_rank(&wanted, &facts("Show", Some(12)));
        let dub = tie_rank(&wanted, &facts("Show (Dub ID)", Some(12)));
        let uncut = tie_rank(&wanted, &facts("Show (Uncensored)", Some(12)));
        assert!(plain < dub);
        assert!(plain < uncut);
        assert!(uncut < dub);
    }

    #[test]
    fn a_matching_unit_count_ranks_first_for_a_finished_title() {
        let wanted = target(Some(12), MediaStatus::Finished);
        let right = tie_rank(&wanted, &facts("Show", Some(12)));
        let wrong = tie_rank(&wanted, &facts("Show", Some(26)));
        assert!(right < wrong);
    }

    #[test]
    fn a_running_title_ignores_the_unit_count() {
        let wanted = target(Some(12), MediaStatus::Releasing);
        assert_eq!(
            tie_rank(&wanted, &facts("Show", Some(3))),
            tie_rank(&wanted, &facts("Show", Some(12)))
        );
    }
}
