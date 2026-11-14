use std::collections::HashMap;

fn bigrams(characters: &[char]) -> HashMap<(char, char), u32> {
    let mut counts = HashMap::new();
    for pair in characters.windows(2) {
        *counts.entry((pair[0], pair[1])).or_insert(0) += 1;
    }
    counts
}

pub fn dice_coefficient(left: &str, right: &str) -> f64 {
    if left == right {
        return if left.is_empty() { 0.0 } else { 1.0 };
    }
    let left_chars: Vec<char> = left.chars().collect();
    let right_chars: Vec<char> = right.chars().collect();
    if left_chars.len() < 2 || right_chars.len() < 2 {
        return 0.0;
    }
    let left_pairs = bigrams(&left_chars);
    let right_pairs = bigrams(&right_chars);
    let shared: u32 = left_pairs
        .iter()
        .map(|(pair, count)| (*count).min(right_pairs.get(pair).copied().unwrap_or(0)))
        .sum();
    let total = (left_chars.len() - 1 + right_chars.len() - 1) as f64;
    2.0 * f64::from(shared) / total
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn identical_text_scores_one() {
        assert_eq!(dice_coefficient("one piece", "one piece"), 1.0);
    }

    #[test]
    fn unrelated_text_scores_near_zero() {
        assert!(dice_coefficient("one piece", "zzzz qqqq") < 0.1);
    }

    #[test]
    fn empty_or_single_character_text_scores_zero() {
        assert_eq!(dice_coefficient("", ""), 0.0);
        assert_eq!(dice_coefficient("a", "ab"), 0.0);
    }

    #[test]
    fn partial_overlap_is_between_zero_and_one() {
        let score = dice_coefficient("night", "nacht");
        assert!(score > 0.0 && score < 1.0);
    }

    #[test]
    fn repeated_pairs_are_counted_with_multiplicity() {
        assert!(dice_coefficient("aaaa", "aa") < 1.0);
    }
}
