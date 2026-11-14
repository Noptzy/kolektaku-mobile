const SPOILER_OPEN: &str = "~!";
const SPOILER_CLOSE: &str = "!~";
const BLOCK_TAGS: [&str; 10] = ["br", "p", "div", "li", "ul", "ol", "h1", "h2", "h3", "hr"];
const SOURCE_MARKERS: [&str; 2] = ["(Source:", "(source:"];
const ENTITIES: [(&str, &str); 6] = [
    ("&amp;", "&"),
    ("&quot;", "\""),
    ("&#039;", "'"),
    ("&#39;", "'"),
    ("&lt;", "<"),
    ("&gt;", ">"),
];

fn without_spoilers(text: &str) -> String {
    let mut kept = String::with_capacity(text.len());
    let mut rest = text;
    while let Some(start) = rest.find(SPOILER_OPEN) {
        kept.push_str(&rest[..start]);
        let after = &rest[start + SPOILER_OPEN.len()..];
        match after.find(SPOILER_CLOSE) {
            Some(end) => rest = &after[end + SPOILER_CLOSE.len()..],
            None => return kept,
        }
    }
    kept.push_str(rest);
    kept
}

fn breaks_a_line(tag: &str) -> bool {
    let name = tag
        .trim_start_matches('/')
        .split(|symbol: char| symbol.is_whitespace() || symbol == '/')
        .next()
        .unwrap_or_default()
        .to_ascii_lowercase();
    BLOCK_TAGS.contains(&name.as_str())
}

fn without_tags(text: &str) -> String {
    let mut kept = String::with_capacity(text.len());
    let mut tag = String::new();
    let mut inside = false;
    for symbol in text.chars() {
        match symbol {
            '<' => {
                inside = true;
                tag.clear();
            }
            '>' if inside => {
                inside = false;
                if breaks_a_line(&tag) {
                    kept.push(' ');
                }
            }
            _ if inside => tag.push(symbol),
            _ => kept.push(symbol),
        }
    }
    kept
}

fn without_source_note(text: &str) -> &str {
    SOURCE_MARKERS
        .iter()
        .filter_map(|marker| text.find(marker))
        .min()
        .map_or(text, |cut| &text[..cut])
}

fn decoded(text: &str) -> String {
    ENTITIES
        .iter()
        .fold(text.to_string(), |acc, (code, plain)| {
            acc.replace(code, plain)
        })
}

pub fn brief_synopsis(raw: &str, max_words: usize) -> Option<String> {
    let plain = decoded(&without_tags(&without_spoilers(raw)));
    let body = without_source_note(&plain);
    let words: Vec<&str> = body.split_whitespace().collect();
    if words.is_empty() || max_words == 0 {
        return None;
    }
    if words.len() <= max_words {
        return Some(words.join(" "));
    }
    Some(format!("{}…", words[..max_words].join(" ")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn short_text_is_kept_whole_with_tidy_spacing() {
        assert_eq!(
            brief_synopsis("  A   quiet\n\nvillage. ", 100).as_deref(),
            Some("A quiet village.")
        );
    }

    #[test]
    fn long_text_is_cut_to_the_word_limit_with_an_ellipsis() {
        let text = (1..=150)
            .map(|n| format!("w{n}"))
            .collect::<Vec<_>>()
            .join(" ");
        let cut = brief_synopsis(&text, 100).unwrap();
        assert!(cut.ends_with("w100…"));
        assert_eq!(cut.trim_end_matches('…').split(' ').count(), 100);
    }

    #[test]
    fn exactly_the_limit_gets_no_ellipsis() {
        let text = (1..=100)
            .map(|n| format!("w{n}"))
            .collect::<Vec<_>>()
            .join(" ");
        assert!(!brief_synopsis(&text, 100).unwrap().ends_with('…'));
    }

    #[test]
    fn spoiler_blocks_are_removed() {
        assert_eq!(
            brief_synopsis("Before ~!the twist!~ after.", 100).as_deref(),
            Some("Before after.")
        );
    }

    #[test]
    fn an_unclosed_spoiler_drops_the_rest() {
        assert_eq!(
            brief_synopsis("Safe ~!never ends", 100).as_deref(),
            Some("Safe")
        );
    }

    #[test]
    fn tags_and_breaks_become_spaces() {
        assert_eq!(
            brief_synopsis("One<br>Two <i>Three</i>", 100).as_deref(),
            Some("One Two Three")
        );
    }

    #[test]
    fn inline_tags_vanish_without_leaving_a_gap() {
        assert_eq!(
            brief_synopsis("Isekai Seikatsu</i>. <b>Bold</b>text", 100).as_deref(),
            Some("Isekai Seikatsu. Boldtext")
        );
    }

    #[test]
    fn block_tags_with_attributes_still_break_the_line() {
        assert_eq!(
            brief_synopsis("One<p class=\"x\">Two</p>Three<BR/>Four", 100).as_deref(),
            Some("One Two Three Four")
        );
    }

    #[test]
    fn the_source_note_is_dropped() {
        assert_eq!(
            brief_synopsis("Plot here. (Source: Somewhere)", 100).as_deref(),
            Some("Plot here.")
        );
    }

    #[test]
    fn common_entities_are_decoded() {
        assert_eq!(
            brief_synopsis("Tom &amp; Jerry &quot;win&quot;", 100).as_deref(),
            Some("Tom & Jerry \"win\"")
        );
    }

    #[test]
    fn empty_or_blank_text_gives_nothing() {
        assert_eq!(brief_synopsis("   ", 100), None);
        assert_eq!(brief_synopsis("~!only spoiler!~", 100), None);
        assert_eq!(brief_synopsis("text", 0), None);
    }
}
