pub fn is_slug(text: &str, extra_allowed: &[char]) -> bool {
    text.starts_with(|c: char| c.is_ascii_alphanumeric())
        && text
            .chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '-' || extra_allowed.contains(&c))
}

pub fn slug_in(text: &str, extra_allowed: &[char]) -> Option<String> {
    let end = text
        .find(|c: char| !(c.is_ascii_alphanumeric() || c == '-' || extra_allowed.contains(&c)))
        .unwrap_or(text.len());
    (end > 0).then(|| text[..end].to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_slug_starts_alphanumeric_and_uses_only_allowed_characters() {
        assert!(is_slug("123213-chainsaw-man", &['.', '_']));
        assert!(is_slug("a.b_c", &['.', '_']));
        assert!(!is_slug("a.b", &[]));
        assert!(!is_slug("-x", &[]));
        assert!(!is_slug("../x", &['.']));
        assert!(!is_slug("a/b", &[]));
        assert!(!is_slug("", &[]));
    }

    #[test]
    fn slug_in_takes_the_leading_slug_characters() {
        assert_eq!(slug_in("one-piece/rest", &[]).as_deref(), Some("one-piece"));
        assert_eq!(slug_in("a.b-c?x", &['.']).as_deref(), Some("a.b-c"));
        assert_eq!(slug_in("/nothing", &[]), None);
    }
}
