use super::relax::{loose_similarity, relaxed_queries};

#[test]
fn a_three_word_keyword_relaxes_to_its_first_two_words() {
    assert_eq!(relaxed_queries("kimi no nawa"), vec!["kimi no"]);
}

#[test]
fn a_longer_keyword_relaxes_two_ways() {
    assert_eq!(
        relaxed_queries("kimetsu no yaiba yuukaku hen"),
        vec!["kimetsu no", "kimetsu no yaiba yuukaku"]
    );
}

#[test]
fn a_two_word_keyword_only_loses_its_last_word() {
    assert_eq!(relaxed_queries("one piece"), vec!["one"]);
}

#[test]
fn a_single_word_cannot_be_relaxed() {
    assert!(relaxed_queries("naruto").is_empty());
    assert!(relaxed_queries("   ").is_empty());
}

#[test]
fn extra_spaces_do_not_matter() {
    assert_eq!(relaxed_queries("  kimi   no  nawa "), vec!["kimi no"]);
}

#[test]
fn spacing_differences_do_not_hurt_the_similarity() {
    assert_eq!(loose_similarity("kimi no nawa", "Kimi no Na wa."), 1.0);
    assert_eq!(loose_similarity("KIMI NO NAWA", "kimi-no-na-wa"), 1.0);
}

#[test]
fn unrelated_titles_score_low() {
    assert!(loose_similarity("kimi no nawa", "Kimi no Suizou wo Tabetai") < 0.6);
    assert!(loose_similarity("kimi no nawa", "One Piece") < 0.3);
}

#[test]
fn empty_text_scores_zero() {
    assert_eq!(loose_similarity("", "Kimi no Na wa."), 0.0);
    assert_eq!(loose_similarity("kimi", ""), 0.0);
}
