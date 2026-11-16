use super::dice::dice_coefficient;

const MIN_DIFFERENCE_LETTERS: usize = 4;
const CONFLICT_DICE: f64 = 0.5;

fn leftover(own: &[String], other: &[String]) -> String {
    own.iter()
        .filter(|token| !other.contains(token))
        .cloned()
        .collect::<Vec<_>>()
        .join("")
}

pub fn distinct_parts_conflict(left: &[String], right: &[String]) -> bool {
    let left_rest = leftover(left, right);
    let right_rest = leftover(right, left);
    let long_enough = |text: &str| text.chars().count() >= MIN_DIFFERENCE_LETTERS;
    long_enough(&left_rest)
        && long_enough(&right_rest)
        && dice_coefficient(&left_rest, &right_rest) < CONFLICT_DICE
}

#[cfg(test)]
mod tests {
    use super::*;

    fn tokens(text: &str) -> Vec<String> {
        text.split(' ').map(str::to_string).collect()
    }

    #[test]
    fn two_arcs_of_one_franchise_conflict() {
        let left = tokens("kimetsu no yaiba yuukaku hen");
        let right = tokens("kimetsu no yaiba katanakaji no sato hen");
        assert!(distinct_parts_conflict(&left, &right));
        let english = tokens("demon slayer kimetsu no yaiba mugen train arc");
        assert!(distinct_parts_conflict(&left, &english));
    }

    #[test]
    fn a_title_that_only_adds_words_does_not_conflict() {
        let short = tokens("kimetsu no yaiba");
        let long = tokens("kimetsu no yaiba yuukaku hen");
        assert!(!distinct_parts_conflict(&short, &long));
        assert!(!distinct_parts_conflict(&long, &short));
    }

    #[test]
    fn spelling_that_only_differs_in_spacing_does_not_conflict() {
        let joined = tokens("kimetsu no yaiba mugenjouhen");
        let split = tokens("kimetsu no yaiba mugen jou hen");
        assert!(!distinct_parts_conflict(&joined, &split));
    }

    #[test]
    fn identical_titles_do_not_conflict() {
        let same = tokens("one piece");
        assert!(!distinct_parts_conflict(&same, &same));
    }

    #[test]
    fn short_leftovers_are_too_small_to_judge() {
        assert!(!distinct_parts_conflict(
            &tokens("show ab"),
            &tokens("show cd")
        ));
    }
}
