use super::tidy::remove_spoilers;

fn href_of(tag: &str) -> Option<String> {
    let lower = tag.to_ascii_lowercase();
    let at = lower.find("href=")?;
    let rest = &tag[at + 5..];
    let quote = rest.chars().next().filter(|c| *c == '"' || *c == '\'')?;
    let inner = &rest[1..];
    let end = inner.find(quote)?;
    Some(inner[..end].trim().to_string())
}

pub fn extract_urls(html: &str) -> Vec<String> {
    let text = remove_spoilers(html);
    let mut found: Vec<String> = Vec::new();
    let mut rest = text.as_str();
    while let Some(start) = rest.find("<a") {
        let after = &rest[start..];
        let is_anchor = after[2..].chars().next().is_some_and(|c| c.is_whitespace());
        let Some(end) = after.find('>') else {
            break;
        };
        if is_anchor
            && let Some(url) = href_of(&after[..end])
            && !found.contains(&url)
        {
            found.push(url);
        }
        rest = &after[end + 1..];
    }
    found
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_hrefs_with_either_quote_style() {
        let html =
            "<p><a href=\"https://twitter.com/a\">X</a> y <a href='https://b.test/c'>c</a></p>";
        assert_eq!(
            extract_urls(html),
            ["https://twitter.com/a", "https://b.test/c"]
        );
    }

    #[test]
    fn ignores_other_tags_and_duplicates() {
        let html = "<abbr title=\"x\">t</abbr><a href=\"https://a.test\">1</a><a href=\"https://a.test\">2</a>";
        assert_eq!(extract_urls(html), ["https://a.test"]);
    }

    #[test]
    fn links_inside_spoilers_are_never_returned() {
        let html = "~!<a href=\"https://spoiler.test\">s</a>!~ <a href=\"https://ok.test\">o</a>";
        assert_eq!(extract_urls(html), ["https://ok.test"]);
    }

    #[test]
    fn anchors_without_a_quoted_href_are_skipped() {
        assert!(extract_urls("<a name=x>t</a><a href=plain>t</a>").is_empty());
        assert!(extract_urls("no links here").is_empty());
    }
}
