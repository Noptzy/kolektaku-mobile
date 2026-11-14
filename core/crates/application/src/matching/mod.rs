mod assign_page;
mod dice;
mod family;
mod marks;
mod noise;
mod normalize;
mod numbers;
mod pick;
mod relax;
mod score;
mod similarity;
mod target;
mod tokenize;

#[cfg(test)]
mod assign_page_tests;
#[cfg(test)]
mod case_support;
#[cfg(test)]
mod fallback_cases;
#[cfg(test)]
mod relax_tests;
#[cfg(test)]
mod required_cases;

pub use assign_page::{Assignment, PageItem, assign_page};
pub use dice::dice_coefficient;
pub use marks::{FormatMark, TitleMarks};
pub use normalize::{NormalizedTitle, normalize_title};
pub use pick::{
    ListedCandidate, PickedCandidate, VerifiedCandidate, pick_best_candidate, shortlist_candidates,
};
pub use relax::{loose_similarity, relaxed_queries};
pub use score::{
    AUTO_CONFIDENCE, MINIMUM_CONFIDENCE, MatchDecision, TITLE_SHORTLIST_SCORE, decide_match,
    score_candidate, score_title,
};
pub use similarity::{Disagreement, compare_marks, title_similarity};
pub use target::{CandidateFacts, MatchTarget};
