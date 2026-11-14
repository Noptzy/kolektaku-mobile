use url::Url;

pub fn host_allowed(patterns: &[&str], address: &str) -> bool {
    let Ok(url) = Url::parse(address) else {
        return false;
    };
    let Some(host) = url.host_str().map(str::to_lowercase) else {
        return false;
    };
    url.scheme() == "https"
        && patterns
            .iter()
            .any(|pattern| matches_pattern(pattern, &host))
}

fn matches_pattern(pattern: &str, host: &str) -> bool {
    let pattern = pattern.to_lowercase();
    match pattern.strip_prefix("*.") {
        Some(suffix) => host
            .strip_suffix(suffix)
            .is_some_and(|prefix| prefix.ends_with('.') && prefix.len() > 1),
        None => host == pattern,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn an_exact_pattern_matches_only_that_host() {
        assert!(host_allowed(&["komiku.org"], "https://komiku.org/manga"));
        assert!(!host_allowed(&["komiku.org"], "https://api.komiku.org"));
        assert!(!host_allowed(
            &["komiku.org"],
            "https://komiku.org.evil.test"
        ));
    }

    #[test]
    fn a_wildcard_matches_subdomains_but_not_the_bare_domain() {
        let patterns = ["*.kuramanime.ing"];
        assert!(host_allowed(&patterns, "https://v20.kuramanime.ing"));
        assert!(host_allowed(&patterns, "https://a.b.kuramanime.ing/x"));
        assert!(!host_allowed(&patterns, "https://kuramanime.ing"));
        assert!(!host_allowed(&patterns, "https://evilkuramanime.ing"));
        assert!(!host_allowed(&patterns, "https://kuramanime.ing.evil.test"));
    }

    #[test]
    fn only_https_addresses_with_a_host_are_accepted() {
        assert!(!host_allowed(&["komiku.org"], "http://komiku.org"));
        assert!(!host_allowed(&["komiku.org"], "ftp://komiku.org"));
        assert!(!host_allowed(&["komiku.org"], "not a url"));
        assert!(!host_allowed(&["komiku.org"], "https://"));
    }

    #[test]
    fn matching_ignores_case() {
        assert!(host_allowed(&["Komiku.ORG"], "https://KOMIKU.org"));
    }

    #[test]
    fn no_patterns_allow_nothing() {
        assert!(!host_allowed(&[], "https://komiku.org"));
    }
}
