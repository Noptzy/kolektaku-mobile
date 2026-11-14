use super::dice::dice_coefficient;
use super::marks::TitleMarks;
use super::normalize::{NormalizedTitle, normalize_title};

const HARD_PENALTY: f64 = 0.3;
const SOFT_PENALTY: f64 = 0.7;
const EXTRA_WORDS_PENALTY: f64 = 0.75;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Disagreement {
    Hard,
    Soft,
    None,
}

fn first_season(marks: &TitleMarks) -> u32 {
    marks.season.unwrap_or(1)
}

fn seasons_disagree(left: &TitleMarks, right: &TitleMarks) -> bool {
    if left.final_season || right.final_season {
        if left.final_season && right.final_season {
            return false;
        }
        let other = if left.final_season { right } else { left };
        return first_season(other) == 1 && other.season.is_none();
    }
    first_season(left) != first_season(right)
}

pub fn compare_marks(left: &TitleMarks, right: &TitleMarks) -> Disagreement {
    if seasons_disagree(left, right) {
        return Disagreement::Hard;
    }
    if left.part.unwrap_or(1) != right.part.unwrap_or(1) {
        return Disagreement::Hard;
    }
    if let (Some(left_format), Some(right_format)) = (left.format, right.format)
        && left_format != right_format
    {
        return Disagreement::Hard;
    }
    if let (Some(left_number), Some(right_number)) = (left.movie_number, right.movie_number)
        && left_number != right_number
    {
        return Disagreement::Hard;
    }
    if left.format.is_none() != right.format.is_none() {
        return Disagreement::Soft;
    }
    Disagreement::None
}

fn compact(text: &str) -> String {
    text.replace(' ', "")
}

fn is_strict_subset(small: &[String], large: &[String]) -> bool {
    small.len() < large.len() && small.iter().all(|token| large.contains(token))
}

fn similarity(left: &NormalizedTitle, right: &NormalizedTitle) -> f64 {
    let mut score = dice_coefficient(&compact(&left.text), &compact(&right.text));
    match compare_marks(&left.marks, &right.marks) {
        Disagreement::Hard => score *= HARD_PENALTY,
        Disagreement::Soft => score *= SOFT_PENALTY,
        Disagreement::None => {}
    }
    if is_strict_subset(&left.tokens, &right.tokens)
        || is_strict_subset(&right.tokens, &left.tokens)
    {
        score *= EXTRA_WORDS_PENALTY;
    }
    score
}

pub fn title_similarity(wanted_titles: &[String], candidate_title: &str) -> f64 {
    let candidate = normalize_title(candidate_title);
    if candidate.text.is_empty() {
        return 0.0;
    }
    wanted_titles
        .iter()
        .map(|title| normalize_title(title))
        .filter(|wanted| !wanted.text.is_empty())
        .map(|wanted| similarity(&wanted, &candidate))
        .fold(0.0, f64::max)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn titles(values: &[&str]) -> Vec<String> {
        values.iter().map(|value| value.to_string()).collect()
    }

    #[test]
    fn is_case_and_punctuation_insensitive_across_every_known_title() {
        assert!(title_similarity(&titles(&["ONE PIECE", "One Piece"]), "one-piece") > 0.95);
        let frieren = titles(&["Sousou no Frieren", "Frieren: Beyond Journey's End"]);
        assert!(title_similarity(&frieren, "Frieren Beyond Journeys End") > 0.9);
    }

    #[test]
    fn a_different_season_part_or_film_marker_is_penalized() {
        let oshi = titles(&["Oshi no Ko 2nd Season"]);
        assert!(title_similarity(&oshi, "Oshi no Ko") < 0.4);
        assert!(title_similarity(&oshi, "Oshi no Ko Season 2") > 0.95);
        assert!(title_similarity(&titles(&["One Piece"]), "One Piece Film: Red") < 0.45);
    }

    #[test]
    fn a_title_that_merely_contains_another_is_not_the_same_entry() {
        let wanted = titles(&["Kimetsu no Yaiba: Yuukaku-hen"]);
        assert!(title_similarity(&wanted, "Kimetsu no Yaiba") < 0.6);
    }

    #[test]
    fn romanization_spacing_does_not_matter() {
        assert!(title_similarity(&titles(&["Re:Zero"]), "Re Zero") > 0.95);
        assert!(title_similarity(&titles(&["SPY×FAMILY"]), "Spy x Family") > 0.95);
    }

    #[test]
    fn empty_titles_score_zero() {
        assert_eq!(title_similarity(&titles(&["One Piece"]), "   "), 0.0);
        assert_eq!(title_similarity(&titles(&[""]), "One Piece"), 0.0);
    }

    #[test]
    fn final_season_disagrees_with_an_unmarked_first_season() {
        let final_marks = normalize_title("Show Final Season").marks;
        let first = normalize_title("Show").marks;
        let third = normalize_title("Show Season 3").marks;
        assert_eq!(compare_marks(&final_marks, &first), Disagreement::Hard);
        assert_eq!(compare_marks(&final_marks, &third), Disagreement::None);
        assert_eq!(
            compare_marks(&final_marks, &final_marks),
            Disagreement::None
        );
    }

    #[test]
    fn one_side_naming_a_format_is_a_soft_disagreement() {
        let movie = normalize_title("Show Movie").marks;
        let plain = normalize_title("Show").marks;
        assert_eq!(compare_marks(&movie, &plain), Disagreement::Soft);
    }

    #[test]
    fn different_movie_numbers_are_a_hard_disagreement() {
        let first = normalize_title("Show Movie 1").marks;
        let second = normalize_title("Show Movie 2").marks;
        assert_eq!(compare_marks(&first, &second), Disagreement::Hard);
    }
}
