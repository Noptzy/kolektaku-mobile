mod assign_page;
mod audio_variant;
mod catalog_ids;
mod dice;
mod family;
mod marks;
mod noise;
mod normalize;
mod novel_title;
mod numbers;
mod pick;
mod refusal;
mod relax;
mod score;
mod similarity;
mod subtitle;
mod target;
mod tie_break;
mod tokenize;
mod version;

#[cfg(test)]
mod assign_page_tests;
#[cfg(test)]
mod case_support;
#[cfg(test)]
mod fallback_cases;
#[cfg(test)]
mod novel_title_spacing_tests;
#[cfg(test)]
mod novel_title_tests;
#[cfg(test)]
mod relax_tests;
#[cfg(test)]
mod required_cases;

pub use assign_page::{Assignment, PageItem, assign_page};
pub use audio_variant::{SplitTitle, audio_variant_of, split_audio, without_audio_marker};
pub use catalog_ids::{CatalogIds, Verdict};
pub use dice::dice_coefficient;
pub use marks::{FormatMark, TitleMarks};
pub use normalize::{NormalizedTitle, normalize_title};
pub use pick::{
    ListedCandidate, PickedCandidate, VerifiedCandidate, pick_best_candidate, shortlist_candidates,
};
pub use refusal::{Refusal, refusal_of};
pub use relax::{loose_similarity, relaxed_queries};
pub use score::{
    AUTO_CONFIDENCE, MINIMUM_CONFIDENCE, MatchDecision, TITLE_SHORTLIST_SCORE, decide_match,
    score_candidate, score_title,
};
pub use similarity::{Disagreement, compare_marks, title_similarity};
pub use target::{CandidateFacts, MatchTarget};
pub use tie_break::tie_rank;
pub use version::MATCHER_VERSION;
