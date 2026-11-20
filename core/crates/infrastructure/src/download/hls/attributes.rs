pub fn parse_attributes(text: &str) -> Vec<(String, String)> {
    let mut pairs = Vec::new();
    let mut rest = text.trim();
    while !rest.is_empty() {
        let Some(equals) = rest.find('=') else { break };
        let name = rest[..equals].trim().to_ascii_uppercase();
        let after = &rest[equals + 1..];
        let (value, remaining) = if let Some(quoted) = after.strip_prefix('"') {
            match quoted.find('"') {
                Some(end) => (&quoted[..end], quoted[end + 1..].trim_start_matches(',')),
                None => (quoted, ""),
            }
        } else {
            match after.find(',') {
                Some(end) => (&after[..end], &after[end + 1..]),
                None => (after, ""),
            }
        };
        pairs.push((name, value.trim().to_string()));
        rest = remaining.trim_start();
    }
    pairs
}

pub fn attribute<'a>(pairs: &'a [(String, String)], name: &str) -> Option<&'a str> {
    pairs
        .iter()
        .find(|(key, _)| key == name)
        .map(|(_, value)| value.as_str())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plain_and_quoted_values_are_read_with_commas_inside_quotes() {
        let pairs = parse_attributes(
            r#"BANDWIDTH=900000,RESOLUTION=640x360,CODECS="avc1.4d401e,mp4a.40.2",AUDIO="aud""#,
        );
        assert_eq!(attribute(&pairs, "BANDWIDTH"), Some("900000"));
        assert_eq!(attribute(&pairs, "RESOLUTION"), Some("640x360"));
        assert_eq!(attribute(&pairs, "CODECS"), Some("avc1.4d401e,mp4a.40.2"));
        assert_eq!(attribute(&pairs, "AUDIO"), Some("aud"));
        assert_eq!(attribute(&pairs, "MISSING"), None);
    }

    #[test]
    fn names_are_matched_in_upper_case_and_broken_input_stops_cleanly() {
        let pairs = parse_attributes(r#"type=AUDIO,NAME="Unclosed"#);
        assert_eq!(attribute(&pairs, "TYPE"), Some("AUDIO"));
        assert_eq!(attribute(&pairs, "NAME"), Some("Unclosed"));
        assert!(parse_attributes("").is_empty());
        assert!(parse_attributes("garbage").is_empty());
    }
}
