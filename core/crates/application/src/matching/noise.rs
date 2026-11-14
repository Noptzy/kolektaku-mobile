const NOISE_PHRASES: [&[&str]; 5] = [
    &["subtitle", "indonesia"],
    &["subtitle", "indo"],
    &["sub", "indonesia"],
    &["sub", "indo"],
    &["batch"],
];

pub fn strip_noise_groups(title: &str) -> String {
    let mut cleaned = String::with_capacity(title.len());
    let mut rest = title;
    while let Some(open) = rest.find('(') {
        cleaned.push_str(&rest[..open]);
        let after_open = &rest[open + 1..];
        match after_open.find(')') {
            Some(close) if is_noise_group(&after_open[..close]) => {
                cleaned.push(' ');
                rest = &after_open[close + 1..];
            }
            _ => {
                cleaned.push('(');
                rest = after_open;
            }
        }
    }
    cleaned.push_str(rest);
    cleaned
}

pub fn strip_noise_phrases(tokens: Vec<String>) -> Vec<String> {
    let mut kept = Vec::with_capacity(tokens.len());
    let mut index = 0;
    while index < tokens.len() {
        let skipped = NOISE_PHRASES
            .iter()
            .find(|phrase| starts_with_phrase(&tokens[index..], phrase))
            .map_or(0, |phrase| phrase.len());
        if skipped == 0 {
            kept.push(tokens[index].clone());
            index += 1;
        } else {
            index += skipped;
        }
    }
    kept
}

fn starts_with_phrase(tokens: &[String], phrase: &[&str]) -> bool {
    tokens.len() >= phrase.len() && tokens.iter().zip(phrase).all(|(token, word)| token == word)
}

fn is_noise_group(inner: &str) -> bool {
    let lower = inner.to_lowercase();
    matches!(
        lower.as_str(),
        "tv" | "ova" | "ona" | "movie" | "special" | "batch"
    ) || lower.starts_with("sub")
        || lower.starts_with("dub")
        || is_year(&lower)
        || is_episode_count(&lower)
}

fn is_year(text: &str) -> bool {
    text.len() == 4 && text.chars().all(|character| character.is_ascii_digit())
}

fn is_episode_count(text: &str) -> bool {
    let digits = text.chars().take_while(char::is_ascii_digit).count();
    let suffix = text[digits..].trim_start();
    digits > 0 && (suffix == "ep" || suffix == "eps")
}

#[cfg(test)]
mod tests {
    use super::*;

    fn words(text: &[&str]) -> Vec<String> {
        text.iter().map(|word| word.to_string()).collect()
    }

    #[test]
    fn removes_type_year_and_episode_count_groups() {
        assert_eq!(strip_noise_groups("Naruto (TV)").trim(), "Naruto");
        assert_eq!(strip_noise_groups("One Piece (1999)").trim(), "One Piece");
        assert_eq!(strip_noise_groups("Bleach (366 eps)").trim(), "Bleach");
        assert_eq!(strip_noise_groups("Show (Sub Indo Batch)").trim(), "Show");
    }

    #[test]
    fn keeps_groups_that_are_part_of_the_title() {
        assert_eq!(strip_noise_groups("Show (Reborn)"), "Show (Reborn)");
        assert_eq!(strip_noise_groups("Show (unclosed"), "Show (unclosed");
    }

    #[test]
    fn removes_subtitle_phrases_and_batch() {
        let tokens = words(&["naruto", "subtitle", "indonesia", "batch"]);
        assert_eq!(strip_noise_phrases(tokens), words(&["naruto"]));
        let tokens = words(&["naruto", "sub", "indo"]);
        assert_eq!(strip_noise_phrases(tokens), words(&["naruto"]));
    }

    #[test]
    fn keeps_unrelated_words() {
        let tokens = words(&["sub", "zero", "indonesian"]);
        assert_eq!(strip_noise_phrases(tokens.clone()), tokens);
    }
}
