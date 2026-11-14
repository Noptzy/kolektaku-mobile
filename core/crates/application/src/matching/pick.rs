use super::score::{
    MatchDecision, TITLE_SHORTLIST_SCORE, decide_match, score_candidate, score_title,
};
use super::target::{CandidateFacts, MatchTarget};

const SHORTLIST_SIZE: usize = 3;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ListedCandidate {
    pub key: String,
    pub title: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VerifiedCandidate {
    pub key: String,
    pub facts: CandidateFacts,
}

#[derive(Debug, Clone, PartialEq)]
pub struct PickedCandidate {
    pub key: String,
    pub confidence: f64,
    pub decision: MatchDecision,
}

pub fn shortlist_candidates(
    target: &MatchTarget,
    listed: &[ListedCandidate],
) -> Vec<ListedCandidate> {
    let mut scored: Vec<(&ListedCandidate, f64)> = listed
        .iter()
        .map(|candidate| (candidate, score_title(target, &candidate.title)))
        .filter(|(_, score)| *score >= TITLE_SHORTLIST_SCORE)
        .collect();
    scored.sort_by(|left, right| right.1.total_cmp(&left.1));
    scored
        .into_iter()
        .take(SHORTLIST_SIZE)
        .map(|(candidate, _)| candidate.clone())
        .collect()
}

pub fn pick_best_candidate(
    target: &MatchTarget,
    verified: &[VerifiedCandidate],
) -> Option<PickedCandidate> {
    let mut best: Option<PickedCandidate> = None;
    for candidate in verified {
        let confidence = score_candidate(target, &candidate.facts);
        if best
            .as_ref()
            .is_none_or(|current| confidence > current.confidence)
        {
            best = Some(PickedCandidate {
                key: candidate.key.clone(),
                confidence,
                decision: decide_match(confidence),
            });
        }
    }
    best.filter(|picked| picked.decision != MatchDecision::None)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn target(title: &str) -> MatchTarget {
        MatchTarget {
            titles: vec![title.to_string()],
            format: None,
            year: None,
            unit_count: None,
            status: None,
        }
    }

    fn listed(key: &str, title: &str) -> ListedCandidate {
        ListedCandidate {
            key: key.into(),
            title: title.into(),
        }
    }

    fn verified(key: &str, title: &str) -> VerifiedCandidate {
        let facts = CandidateFacts {
            titles: vec![title.to_string()],
            type_text: None,
            year: None,
            unit_count: None,
        };
        VerifiedCandidate {
            key: key.into(),
            facts,
        }
    }

    #[test]
    fn shortlist_keeps_only_close_titles_best_first_up_to_three() {
        let candidates = [
            listed("far", "Totally Different"),
            listed("b", "Naruto Shippuden"),
            listed("a", "Naruto"),
            listed("c", "Naruto!"),
            listed("d", "Naruto?"),
        ];
        let keys: Vec<String> = shortlist_candidates(&target("Naruto"), &candidates)
            .into_iter()
            .map(|candidate| candidate.key)
            .collect();
        assert_eq!(keys.len(), 3);
        assert!(!keys.contains(&"far".to_string()));
        assert_eq!(keys[0], "a");
    }

    #[test]
    fn the_first_of_two_equally_good_candidates_wins() {
        let picked = pick_best_candidate(
            &target("Naruto"),
            &[verified("first", "Naruto"), verified("second", "Naruto")],
        )
        .unwrap();
        assert_eq!(picked.key, "first");
        assert_eq!(picked.decision, MatchDecision::Auto);
    }

    #[test]
    fn nothing_convincing_gives_no_pick() {
        let picked = pick_best_candidate(&target("Naruto"), &[verified("x", "One Piece")]);
        assert_eq!(picked, None);
        assert_eq!(pick_best_candidate(&target("Naruto"), &[]), None);
    }
}
