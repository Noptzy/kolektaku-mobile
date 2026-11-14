pub fn small_number(text: &str) -> Option<u32> {
    let is_short = (1..=2).contains(&text.len());
    if is_short && text.bytes().all(|byte| byte.is_ascii_digit()) {
        text.parse().ok()
    } else {
        None
    }
}

pub fn ordinal(text: &str) -> Option<u32> {
    let split = text.len().checked_sub(2)?;
    let suffix = text.get(split..)?;
    if matches!(suffix, "st" | "nd" | "rd" | "th") {
        small_number(text.get(..split)?)
    } else {
        None
    }
}

pub fn season_shorthand(text: &str) -> Option<u32> {
    text.strip_prefix('s').and_then(small_number)
}

pub fn roman_season(text: &str) -> Option<u32> {
    match text {
        "ii" => Some(2),
        "iii" => Some(3),
        "iv" => Some(4),
        _ => None,
    }
}

pub fn lone_digit(text: &str) -> Option<u32> {
    let number = small_number(text)?;
    (text.len() == 1 && (2..=9).contains(&number)).then_some(number)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn small_numbers_have_one_or_two_digits() {
        assert_eq!(small_number("7"), Some(7));
        assert_eq!(small_number("12"), Some(12));
        assert_eq!(small_number("100"), None);
        assert_eq!(small_number(""), None);
        assert_eq!(small_number("1a"), None);
    }

    #[test]
    fn ordinals_need_a_known_suffix() {
        assert_eq!(ordinal("2nd"), Some(2));
        assert_eq!(ordinal("3rd"), Some(3));
        assert_eq!(ordinal("12th"), Some(12));
        assert_eq!(ordinal("2xx"), None);
        assert_eq!(ordinal("st"), None);
    }

    #[test]
    fn season_shorthand_is_an_s_followed_by_a_number() {
        assert_eq!(season_shorthand("s3"), Some(3));
        assert_eq!(season_shorthand("s"), None);
        assert_eq!(season_shorthand("3"), None);
    }

    #[test]
    fn roman_numerals_cover_two_to_four() {
        assert_eq!(roman_season("ii"), Some(2));
        assert_eq!(roman_season("iii"), Some(3));
        assert_eq!(roman_season("iv"), Some(4));
        assert_eq!(roman_season("i"), None);
        assert_eq!(roman_season("v"), None);
    }

    #[test]
    fn a_lone_digit_is_a_season_only_from_two_to_nine() {
        assert_eq!(lone_digit("2"), Some(2));
        assert_eq!(lone_digit("9"), Some(9));
        assert_eq!(lone_digit("1"), None);
        assert_eq!(lone_digit("10"), None);
    }
}
