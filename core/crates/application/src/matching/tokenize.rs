use unicode_normalization::UnicodeNormalization;
use unicode_normalization::char::is_combining_mark;

pub fn tokenize(value: &str) -> Vec<String> {
    let folded: String = value
        .nfkd()
        .filter(|character| !is_combining_mark(*character))
        .collect::<String>()
        .to_lowercase()
        .replace('×', "x")
        .replace('&', " and ");
    folded
        .chars()
        .map(|character| {
            if character.is_alphanumeric() {
                character
            } else {
                ' '
            }
        })
        .collect::<String>()
        .split_whitespace()
        .map(str::to_string)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lowercases_and_strips_punctuation() {
        assert_eq!(
            tokenize("Re:ZERO -Starting Life in Another World-").join(" "),
            "re zero starting life in another world"
        );
    }

    #[test]
    fn strips_diacritics() {
        assert_eq!(tokenize("Pokémon"), vec!["pokemon"]);
    }

    #[test]
    fn multiplication_sign_joins_words_and_ampersand_becomes_a_word() {
        assert_eq!(tokenize("SPY×FAMILY"), vec!["spyxfamily"]);
        assert_eq!(tokenize("Tom & Jerry"), vec!["tom", "and", "jerry"]);
    }

    #[test]
    fn keeps_japanese_text_as_one_token() {
        let tokens = tokenize("ワンピース");
        assert_eq!(tokens.len(), 1);
        assert_eq!(tokens[0].chars().count(), 5);
    }

    #[test]
    fn blank_input_has_no_tokens() {
        assert!(tokenize("  -- ").is_empty());
    }
}
