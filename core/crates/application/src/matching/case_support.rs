use domain::media::{MediaFormat, MediaStatus};

use super::{
    CandidateFacts, ListedCandidate, MatchDecision, MatchTarget, PickedCandidate,
    VerifiedCandidate, pick_best_candidate, shortlist_candidates,
};

pub struct Candidate {
    key: &'static str,
    title: &'static str,
    type_text: &'static str,
    year: u16,
    unit_count: Option<u32>,
}

pub fn candidate(
    key: &'static str,
    title: &'static str,
    type_text: &'static str,
    year: u16,
    unit_count: Option<u32>,
) -> Candidate {
    Candidate {
        key,
        title,
        type_text,
        year,
        unit_count,
    }
}

pub fn wanted(
    titles: &[&str],
    format: MediaFormat,
    year: u16,
    unit_count: Option<u32>,
    status: MediaStatus,
) -> MatchTarget {
    MatchTarget {
        titles: titles.iter().map(|title| title.to_string()).collect(),
        format: Some(format),
        year: Some(year),
        unit_count,
        status: Some(status),
    }
}

pub fn resolve(target: &MatchTarget, candidates: &[Candidate]) -> Option<PickedCandidate> {
    let listed: Vec<ListedCandidate> = candidates
        .iter()
        .map(|item| ListedCandidate {
            key: item.key.into(),
            title: item.title.into(),
        })
        .collect();
    let verified: Vec<VerifiedCandidate> = shortlist_candidates(target, &listed)
        .iter()
        .map(|short| {
            let item = candidates
                .iter()
                .find(|item| item.key == short.key)
                .unwrap();
            VerifiedCandidate {
                key: item.key.into(),
                facts: CandidateFacts {
                    titles: vec![item.title.into()],
                    type_text: Some(item.type_text.into()),
                    year: Some(item.year),
                    unit_count: item.unit_count,
                },
            }
        })
        .collect();
    pick_best_candidate(target, &verified)
}

pub fn assert_auto(picked: Option<PickedCandidate>, key: &str) {
    let picked = picked.expect("a candidate should be picked");
    assert_eq!(picked.key, key);
    assert_eq!(picked.decision, MatchDecision::Auto);
}
