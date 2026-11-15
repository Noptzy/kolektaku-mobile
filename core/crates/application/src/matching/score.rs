use domain::media::MediaStatus;

use super::family::{FormatFamily, family_of_format, family_of_type};
use super::novel_title::{edition_factor, is_novel_target, novel_title_score};
use super::similarity::title_similarity;
use super::target::{CandidateFacts, MatchTarget};

pub const AUTO_CONFIDENCE: f64 = 0.85;
pub const MINIMUM_CONFIDENCE: f64 = 0.6;
pub const TITLE_SHORTLIST_SCORE: f64 = 0.6;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MatchDecision {
    Auto,
    AutoWithHint,
    None,
}

pub fn score_title(target: &MatchTarget, candidate_title: &str) -> f64 {
    if is_novel_target(target) {
        return novel_title_score(&target.titles, &[candidate_title.to_string()]);
    }
    title_similarity(&target.titles, candidate_title)
}

pub fn score_candidate(target: &MatchTarget, facts: &CandidateFacts) -> f64 {
    let title = if is_novel_target(target) {
        novel_title_score(&target.titles, &facts.titles)
    } else {
        facts
            .titles
            .iter()
            .map(|candidate| title_similarity(&target.titles, candidate))
            .fold(0.0, f64::max)
    };
    let mut factor = if is_novel_target(target) {
        edition_factor(facts.type_text.as_deref())
    } else {
        1.0
    };
    let mut bonus = 0.0;

    let wanted = family_of_format(target.format);
    let actual = family_of_type(facts.type_text.as_deref());
    if let (Some(wanted), Some(actual)) = (wanted, actual) {
        if wanted == actual {
            bonus += 0.05;
        } else {
            factor *= 0.45;
        }
    }

    if let (Some(target_year), Some(facts_year)) = (target.year, facts.year) {
        let gap = target_year.abs_diff(facts_year);
        if gap <= 1 {
            bonus += 0.03;
        } else if gap >= 3 {
            factor *= 0.55;
        }
    }

    let airing = matches!(
        target.status,
        Some(MediaStatus::Releasing | MediaStatus::NotYetReleased)
    );
    let counted = !matches!(wanted, Some(FormatFamily::Movie | FormatFamily::Book));
    if let (Some(target_count), Some(facts_count)) = (target.unit_count, facts.unit_count)
        && counted
        && !airing
    {
        if target_count == facts_count {
            bonus += 0.02;
        } else {
            factor *= 0.85;
        }
    }

    (title * factor + bonus).min(1.0)
}

pub fn decide_match(confidence: f64) -> MatchDecision {
    if confidence >= AUTO_CONFIDENCE {
        MatchDecision::Auto
    } else if confidence >= MINIMUM_CONFIDENCE {
        MatchDecision::AutoWithHint
    } else {
        MatchDecision::None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use domain::media::MediaFormat;

    fn target(titles: &[&str]) -> MatchTarget {
        MatchTarget {
            titles: titles.iter().map(|title| title.to_string()).collect(),
            format: None,
            year: None,
            unit_count: None,
            status: Some(MediaStatus::Finished),
        }
    }

    fn facts(
        title: &str,
        type_text: &str,
        year: Option<u16>,
        count: Option<u32>,
    ) -> CandidateFacts {
        CandidateFacts {
            titles: vec![title.to_string()],
            type_text: Some(type_text.to_string()),
            year,
            unit_count: count,
        }
    }

    #[test]
    fn confidence_maps_to_the_three_outcomes() {
        assert_eq!(decide_match(0.9), MatchDecision::Auto);
        assert_eq!(decide_match(0.85), MatchDecision::Auto);
        assert_eq!(decide_match(0.7), MatchDecision::AutoWithHint);
        assert_eq!(decide_match(0.59), MatchDecision::None);
    }

    #[test]
    fn agreeing_facts_raise_confidence_and_disagreeing_facts_lower_it() {
        let mut wanted = target(&["Bocchi the Rock!"]);
        wanted.format = Some(MediaFormat::Tv);
        wanted.year = Some(2022);
        wanted.unit_count = Some(12);
        let agreeing = facts("Bocchi the Rock!", "TV", Some(2022), Some(12));
        assert_eq!(score_candidate(&wanted, &agreeing), 1.0);

        let wrong_type = facts("Bocchi the Rock!", "Movie", Some(2022), Some(12));
        assert_eq!(
            decide_match(score_candidate(&wanted, &wrong_type)),
            MatchDecision::None
        );

        let wrong_year = facts("Bocchi the Rock!", "TV", Some(2010), Some(12));
        assert_ne!(
            decide_match(score_candidate(&wanted, &wrong_year)),
            MatchDecision::Auto
        );
    }

    #[test]
    fn the_episode_count_of_an_airing_show_is_ignored() {
        let mut wanted = target(&["Some Show"]);
        wanted.format = Some(MediaFormat::Tv);
        wanted.status = Some(MediaStatus::Releasing);
        let candidate = facts("Some Show", "TV", None, Some(6));
        assert!(score_candidate(&wanted, &candidate) >= 1.0);
    }

    #[test]
    fn a_wrong_episode_count_lowers_a_finished_series() {
        let mut wanted = target(&["Some Show"]);
        wanted.format = Some(MediaFormat::Tv);
        wanted.unit_count = Some(12);
        let candidate = facts("Some Show", "TV", None, Some(26));
        assert!(score_candidate(&wanted, &candidate) < 1.0);
    }

    #[test]
    fn the_best_alternative_title_counts() {
        let wanted = target(&["Kimi no Na wa."]);
        let candidate = CandidateFacts {
            titles: vec!["Unrelated".into(), "Kimi no Na wa".into()],
            type_text: None,
            year: None,
            unit_count: None,
        };
        assert!(score_candidate(&wanted, &candidate) > 0.9);
    }
}
