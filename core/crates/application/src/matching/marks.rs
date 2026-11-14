use super::numbers::{lone_digit, ordinal, roman_season, season_shorthand, small_number};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FormatMark {
    Movie,
    Ova,
    Special,
    Ona,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct TitleMarks {
    pub season: Option<u32>,
    pub final_season: bool,
    pub part: Option<u32>,
    pub format: Option<FormatMark>,
    pub movie_number: Option<u32>,
}

pub fn extract_marks(tokens: &mut Vec<String>) -> TitleMarks {
    let mut marks = TitleMarks::default();
    let mut index = 0;
    while index < tokens.len() {
        let consumed = read_mark(tokens, index, &mut marks);
        if consumed == 0 {
            index += 1;
        } else {
            tokens.drain(index..index + consumed);
        }
    }
    marks
}

fn read_mark(tokens: &[String], index: usize, marks: &mut TitleMarks) -> usize {
    let token = tokens[index].as_str();
    let next = tokens.get(index + 1).map_or("", String::as_str);
    let has_previous = index > 0;
    let previous = if has_previous {
        tokens[index - 1].as_str()
    } else {
        ""
    };
    let is_last = index + 1 == tokens.len();

    if token == "final" && next == "season" {
        marks.final_season = true;
        2
    } else if token == "season"
        && let Some(number) = small_number(next)
    {
        marks.season = Some(number);
        2
    } else if next == "season"
        && let Some(number) = ordinal(token)
    {
        marks.season = Some(number);
        2
    } else if token == "season"
        && let Some(number) = ordinal(next)
    {
        marks.season = Some(number);
        2
    } else if (token == "part" || token == "cour")
        && let Some(number) = small_number(next)
    {
        marks.part = Some(number);
        2
    } else if has_previous && let Some(number) = season_shorthand(token) {
        marks.season = Some(number);
        1
    } else if token == "movie"
        && let Some(number) = small_number(next)
    {
        marks.format = Some(FormatMark::Movie);
        marks.movie_number = Some(number);
        2
    } else if token == "the" && next == "movie" {
        marks.format = Some(FormatMark::Movie);
        2
    } else if matches!(token, "movie" | "film" | "gekijouban") {
        marks.format = Some(FormatMark::Movie);
        match (token, small_number(next)) {
            ("film", Some(number)) => {
                marks.movie_number = Some(number);
                2
            }
            _ => 1,
        }
    } else if matches!(token, "ova" | "oad" | "oav") {
        marks.format = Some(FormatMark::Ova);
        1
    } else if matches!(token, "special" | "specials") {
        marks.format = Some(FormatMark::Special);
        1
    } else if token == "ona" {
        marks.format = Some(FormatMark::Ona);
        1
    } else if is_last
        && has_previous
        && let Some(number) = roman_season(token)
    {
        marks.season = Some(number);
        1
    } else if is_last
        && has_previous
        && previous != "part"
        && let Some(number) = lone_digit(token)
    {
        marks.season = Some(number);
        1
    } else {
        0
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn marks_of(title: &str) -> (TitleMarks, String) {
        let mut tokens: Vec<String> = title.split(' ').map(str::to_string).collect();
        let marks = extract_marks(&mut tokens);
        (marks, tokens.join(" "))
    }

    #[test]
    fn reads_season_in_every_notation() {
        for title in [
            "oshi no ko 2nd season",
            "oshi no ko season 2",
            "oshi no ko s2",
            "oshi no ko ii",
            "oshi no ko 2",
            "oshi no ko season 2nd",
        ] {
            let (marks, text) = marks_of(title);
            assert_eq!(marks.season, Some(2), "{title}");
            assert_eq!(text, "oshi no ko", "{title}");
        }
    }

    #[test]
    fn reads_final_season_and_part() {
        let (marks, text) = marks_of("shingeki no kyojin the final season part 2");
        assert!(marks.final_season);
        assert_eq!(marks.part, Some(2));
        assert_eq!(text, "shingeki no kyojin the");
    }

    #[test]
    fn reads_movie_markers() {
        assert_eq!(marks_of("one piece movie 1").0.movie_number, Some(1));
        assert_eq!(marks_of("one piece film 3").0.movie_number, Some(3));
        let (marks, text) = marks_of("one piece film red");
        assert_eq!(
            (marks.format, marks.movie_number),
            (Some(FormatMark::Movie), None)
        );
        assert_eq!(text, "one piece red");
        assert_eq!(
            marks_of("spy x family the movie").0.format,
            Some(FormatMark::Movie)
        );
    }

    #[test]
    fn reads_short_formats() {
        assert_eq!(marks_of("bleach ova").0.format, Some(FormatMark::Ova));
        assert_eq!(
            marks_of("bleach specials").0.format,
            Some(FormatMark::Special)
        );
        assert_eq!(marks_of("show ona").0.format, Some(FormatMark::Ona));
    }

    #[test]
    fn keeps_numbers_that_belong_to_the_title() {
        let (marks, text) = marks_of("mob psycho 100");
        assert_eq!(marks.season, None);
        assert_eq!(text, "mob psycho 100");
        assert_eq!(marks_of("mob psycho 100 ii").0.season, Some(2));
    }

    #[test]
    fn a_digit_after_part_is_not_a_season() {
        let (marks, _) = marks_of("show part 2");
        assert_eq!((marks.part, marks.season), (Some(2), None));
    }

    #[test]
    fn a_leading_season_shorthand_is_not_a_season() {
        assert_eq!(marks_of("s2 show").0.season, None);
    }
}
