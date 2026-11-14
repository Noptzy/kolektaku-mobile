const BREAK: &str = "<br>";

pub fn remove_spoilers(text: &str) -> String {
    let mut result = String::new();
    let mut rest = text;
    while let Some(start) = rest.find("~!") {
        let after_open = &rest[start + 2..];
        let Some(end) = after_open.find("!~") else {
            break;
        };
        result.push_str(&rest[..start]);
        rest = &after_open[end + 2..];
    }
    result.push_str(rest);
    result
}

pub fn collapse_newlines(text: &str) -> String {
    let mut result = String::new();
    let mut run = String::new();
    for character in text.chars() {
        if character.is_whitespace() {
            run.push(character);
            continue;
        }
        flush_whitespace(&mut result, &mut run);
        result.push(character);
    }
    flush_whitespace(&mut result, &mut run);
    result
}

fn flush_whitespace(result: &mut String, run: &mut String) {
    if run.contains('\n') {
        result.push(' ');
    } else {
        result.push_str(run);
    }
    run.clear();
}

pub fn collapse_breaks(text: &str) -> String {
    let mut result = String::new();
    let mut rest = text;
    while !rest.is_empty() {
        let (count, consumed) = break_run(rest);
        if count >= 3 {
            result.push_str("<br><br>");
            rest = &rest[consumed..];
        } else if let Some(character) = rest.chars().next() {
            result.push(character);
            rest = &rest[character.len_utf8()..];
        }
    }
    result
}

fn break_run(text: &str) -> (usize, usize) {
    let mut count = 0;
    let mut rest = text;
    while let Some(after) = rest.strip_prefix(BREAK) {
        count += 1;
        rest = after.trim_start();
    }
    (count, text.len() - rest.len())
}

pub fn trim_breaks(text: &str) -> String {
    let mut rest = text;
    loop {
        let trimmed = rest.trim_start();
        match trimmed.strip_prefix(BREAK) {
            Some(after) => rest = after,
            None => {
                rest = trimmed;
                break;
            }
        }
    }
    loop {
        let trimmed = rest.trim_end();
        match trimmed.strip_suffix(BREAK) {
            Some(before) => rest = before,
            None => return trimmed.to_string(),
        }
    }
}

pub fn collapse_spaces(text: &str) -> String {
    let mut result = String::new();
    let mut previous_blank = false;
    for character in text.chars() {
        let blank = character == ' ' || character == '\t';
        if blank && previous_blank {
            continue;
        }
        result.push(if blank { ' ' } else { character });
        previous_blank = blank;
    }
    result
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn spoilers_vanish_even_across_lines_and_unclosed_ones_stay() {
        assert_eq!(remove_spoilers("a ~!x\ny!~ b"), "a  b");
        assert_eq!(remove_spoilers("a ~!never closed"), "a ~!never closed");
        assert_eq!(remove_spoilers("~!a!~~!b!~c"), "c");
    }

    #[test]
    fn a_whitespace_run_with_a_newline_becomes_one_space() {
        assert_eq!(collapse_newlines("a \n  b"), "a b");
        assert_eq!(collapse_newlines("a   b"), "a   b");
        assert_eq!(collapse_newlines("a\n"), "a ");
    }

    #[test]
    fn three_or_more_breaks_become_two() {
        assert_eq!(collapse_breaks("a<br><br><br><br>b"), "a<br><br>b");
        assert_eq!(collapse_breaks("a<br> <br> <br>b"), "a<br><br>b");
        assert_eq!(collapse_breaks("a<br><br>b"), "a<br><br>b");
    }

    #[test]
    fn leading_and_trailing_breaks_and_spaces_are_trimmed() {
        assert_eq!(trim_breaks(" <br><br>a<br> "), "a");
        assert_eq!(trim_breaks("<br>"), "");
    }

    #[test]
    fn runs_of_spaces_and_tabs_become_one_space() {
        assert_eq!(collapse_spaces("a  \t b"), "a b");
        assert_eq!(collapse_spaces("é  é"), "é é");
    }
}
