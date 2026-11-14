const ADULT_LABELS: [&str; 8] = [
    "hentai",
    "adult",
    "dewasa",
    "smut",
    "shotacon",
    "sexual-violence",
    "mature",
    "erotica",
];

const EXPLICIT_TERMS: [&str; 24] = [
    "bdsm",
    "bondage",
    "blowjob",
    "nakadashi",
    "netori",
    "milf",
    "fetish",
    "humiliation",
    "condom",
    "uncensored",
    "steamy",
    "explicit",
    "sex",
    "sexual",
    "penis",
    "breast",
    "breasts",
    "ass",
    "borderline h",
    "x ray",
    "incest",
    "rape",
    "porn",
    "xxx",
];

fn words_of(label: &str) -> String {
    let spaced: String = label
        .to_lowercase()
        .chars()
        .map(|letter| {
            if letter.is_alphanumeric() {
                letter
            } else {
                ' '
            }
        })
        .collect();
    format!(
        " {} ",
        spaced.split_whitespace().collect::<Vec<_>>().join(" ")
    )
}

pub fn is_adult_label(label: &str) -> bool {
    let lower = label.trim().to_lowercase();
    if ADULT_LABELS.contains(&lower.as_str()) {
        return true;
    }
    let words = words_of(label);
    EXPLICIT_TERMS
        .iter()
        .any(|term| words.contains(&format!(" {term} ")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn adult_labels_are_recognized_in_any_case() {
        for label in [
            "hentai",
            "Hentai",
            " ADULT ",
            "Dewasa",
            "sexual-violence",
            "Erotica",
        ] {
            assert!(is_adult_label(label), "{label}");
        }
    }

    #[test]
    fn ordinary_labels_pass() {
        for label in [
            "action",
            "ecchi",
            "romance",
            "",
            "adults only club",
            "Adult Cast",
            "Class",
            "Classic",
            "Passion",
            "Assassin",
            "Mass",
            "Breaking",
            "Sexagenarian",
            "Violence",
            "Gore",
        ] {
            assert!(!is_adult_label(label), "{label}");
        }
    }

    #[test]
    fn explicit_genre_names_are_recognized_as_whole_words() {
        for label in [
            "BDSM",
            "Big Ass",
            "Big Breast",
            "Big Breasts",
            "Big Penis",
            "Blowjob",
            "Bondage",
            "Borderline H",
            "Condom",
            "Explicit Sex",
            "Fetish",
            "Humiliation",
            "MILF",
            "Nakadashi",
            "Netori",
            "Sexual Abuse",
            "Steamy",
            "Uncensored",
            "X-Ray",
            "Free Porn",
        ] {
            assert!(is_adult_label(label), "{label}");
        }
    }
}
