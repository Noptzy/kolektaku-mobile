#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CueShape {
    Merged(String),
    Dialogue(Vec<String>),
    Kept,
}

const DIALOGUE_DASHES: [char; 3] = ['-', '\u{2013}', '\u{2014}'];

pub fn prepare_cue(text: &str) -> CueShape {
    let lines: Vec<&str> = text
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .collect();
    if lines.iter().all(|line| is_only_symbols(line)) {
        return CueShape::Kept;
    }
    if lines.len() > 1 && lines.iter().all(|line| starts_a_speaker_turn(line)) {
        return CueShape::Dialogue(lines.into_iter().map(str::to_string).collect());
    }
    CueShape::Merged(lines.join(" "))
}

fn is_only_symbols(line: &str) -> bool {
    !line.chars().any(char::is_alphanumeric)
}

fn starts_a_speaker_turn(line: &str) -> bool {
    line.starts_with(DIALOGUE_DASHES)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_sentence_broken_over_two_lines_is_joined_with_a_space() {
        assert_eq!(
            prepare_cue("What are you\ntalking about?"),
            CueShape::Merged("What are you talking about?".into())
        );
    }

    #[test]
    fn a_single_line_stays_as_it_is() {
        assert_eq!(prepare_cue("Hello."), CueShape::Merged("Hello.".into()));
    }

    #[test]
    fn two_speakers_stay_two_lines() {
        assert_eq!(
            prepare_cue("- Where are you going?\n- Home."),
            CueShape::Dialogue(vec!["- Where are you going?".into(), "- Home.".into()])
        );
    }

    #[test]
    fn other_dash_kinds_also_mark_speakers() {
        assert_eq!(
            prepare_cue("\u{2013} One\n\u{2014} Two"),
            CueShape::Dialogue(vec!["\u{2013} One".into(), "\u{2014} Two".into()])
        );
    }

    #[test]
    fn only_some_lines_with_a_dash_is_still_one_sentence() {
        assert_eq!(
            prepare_cue("- Wait\nfor me"),
            CueShape::Merged("- Wait for me".into())
        );
    }

    #[test]
    fn a_single_line_with_a_dash_is_not_dialogue() {
        assert_eq!(
            prepare_cue("- Wait for me"),
            CueShape::Merged("- Wait for me".into())
        );
    }

    #[test]
    fn music_notes_and_symbols_are_kept_untranslated() {
        assert_eq!(prepare_cue("\u{266a}"), CueShape::Kept);
        assert_eq!(prepare_cue("\u{266a} \u{266a}\n..."), CueShape::Kept);
        assert_eq!(prepare_cue("!?"), CueShape::Kept);
    }

    #[test]
    fn a_blank_cue_is_kept() {
        assert_eq!(prepare_cue(""), CueShape::Kept);
        assert_eq!(prepare_cue("  \n "), CueShape::Kept);
    }

    #[test]
    fn a_line_with_words_next_to_a_note_is_translated() {
        assert_eq!(
            prepare_cue("\u{266a} la la la \u{266a}"),
            CueShape::Merged("\u{266a} la la la \u{266a}".into())
        );
    }

    #[test]
    fn numbers_count_as_content() {
        assert_eq!(prepare_cue("1999"), CueShape::Merged("1999".into()));
    }

    #[test]
    fn spaces_around_lines_are_dropped_before_joining() {
        assert_eq!(
            prepare_cue("  one  \n  two  "),
            CueShape::Merged("one two".into())
        );
    }
}
