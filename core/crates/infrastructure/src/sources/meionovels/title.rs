use crate::sources::support::collapse;

const EDITION_MARKS: [&str; 2] = ["LN", "WN"];

pub fn clean_title(raw: &str) -> String {
    let mut title = collapse(raw);
    loop {
        let trimmed = title.trim_end_matches([' ', '-', '–']);
        let stripped = strip_bracketed(trimmed).or_else(|| strip_plain(trimmed));
        match stripped {
            Some(shorter) if !shorter.is_empty() => title = shorter,
            _ => return trimmed.to_string(),
        }
    }
}

fn strip_plain(text: &str) -> Option<String> {
    let (head, last) = text.rsplit_once(' ')?;
    EDITION_MARKS
        .contains(&last)
        .then(|| head.trim_end().to_string())
}

fn strip_bracketed(text: &str) -> Option<String> {
    for (open, close) in [('(', ')'), ('[', ']')] {
        let Some((head, mark)) = text
            .strip_suffix(close)
            .and_then(|inner| inner.rsplit_once(open))
        else {
            continue;
        };
        if EDITION_MARKS.contains(&mark.trim()) {
            return Some(head.trim_end().to_string());
        }
    }
    None
}
