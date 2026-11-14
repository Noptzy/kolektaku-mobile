use super::marks::{TitleMarks, extract_marks};
use super::noise::{strip_noise_groups, strip_noise_phrases};
use super::tokenize::tokenize;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NormalizedTitle {
    pub text: String,
    pub tokens: Vec<String>,
    pub marks: TitleMarks,
}

pub fn normalize_title(title: &str) -> NormalizedTitle {
    let cleaned = strip_noise_groups(title);
    let mut tokens = strip_noise_phrases(tokenize(&cleaned));
    let marks = extract_marks(&mut tokens);
    NormalizedTitle {
        text: tokens.join(" "),
        tokens,
        marks,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::matching::marks::FormatMark;

    #[test]
    fn lowercases_strips_punctuation_and_diacritics() {
        assert_eq!(
            normalize_title("Re:ZERO -Starting Life in Another World-").text,
            "re zero starting life in another world"
        );
        assert_eq!(normalize_title("Pokémon").text, "pokemon");
    }

    #[test]
    fn reads_the_season_from_every_notation() {
        let cases = [
            ("Oshi no Ko 2nd Season", 2),
            ("Oshi no Ko Season 2", 2),
            ("Oshi no Ko S2", 2),
            ("Oshi no Ko II", 2),
            ("Oshi no Ko 2", 2),
            ("Oshi no Ko Season 3", 3),
        ];
        for (title, season) in cases {
            let result = normalize_title(title);
            assert_eq!(result.marks.season, Some(season), "{title}");
            assert_eq!(result.text, "oshi no ko", "{title}");
        }
    }

    #[test]
    fn keeps_numbers_that_belong_to_the_title() {
        assert_eq!(normalize_title("Mob Psycho 100").text, "mob psycho 100");
        assert_eq!(normalize_title("Mob Psycho 100 II").marks.season, Some(2));
    }

    #[test]
    fn reads_part_final_season_movie_number_and_format() {
        let final_part = normalize_title("Shingeki no Kyojin: The Final Season Part 2").marks;
        assert!(final_part.final_season);
        assert_eq!(final_part.part, Some(2));

        let movie = normalize_title("One Piece Movie 1").marks;
        assert_eq!(
            (movie.format, movie.movie_number),
            (Some(FormatMark::Movie), Some(1))
        );

        let film = normalize_title("One Piece Film: Red").marks;
        assert_eq!(
            (film.format, film.movie_number),
            (Some(FormatMark::Movie), None)
        );

        assert_eq!(normalize_title("Kimi no Na wa. (Movie)").marks.format, None);
        assert_eq!(
            normalize_title("Bleach OVA").marks.format,
            Some(FormatMark::Ova)
        );
    }

    #[test]
    fn drops_provider_noise() {
        assert_eq!(
            normalize_title("Naruto (TV) Subtitle Indonesia").text,
            "naruto"
        );
        assert_eq!(normalize_title("One Piece (1999)").text, "one piece");
    }

    #[test]
    fn tokens_match_the_text() {
        let result = normalize_title("Kimi no Na wa.");
        assert_eq!(result.tokens.join(" "), result.text);
    }
}
