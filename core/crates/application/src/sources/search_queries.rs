use domain::media::MediaSummary;

const MAX_SYNONYM_QUERIES: usize = 3;
const MIN_LETTERS: usize = 3;

fn is_latin_letter(symbol: char) -> bool {
    symbol.is_ascii_alphabetic()
        || ('\u{00C0}'..='\u{024F}').contains(&symbol)
        || ('\u{1E00}'..='\u{1EFF}').contains(&symbol)
}

fn is_latin_title(text: &str) -> bool {
    let mut letters = 0;
    for symbol in text.chars().filter(|symbol| symbol.is_alphabetic()) {
        if !is_latin_letter(symbol) {
            return false;
        }
        letters += 1;
    }
    letters >= MIN_LETTERS
}

fn is_new(queries: &[String], candidate: &str) -> bool {
    !queries
        .iter()
        .any(|known| known.eq_ignore_ascii_case(candidate))
}

pub fn search_queries(media: &MediaSummary) -> Vec<String> {
    let mut queries = vec![media.title.romaji.clone()];
    let english = media
        .title
        .english
        .as_deref()
        .map(str::trim)
        .filter(|name| !name.is_empty());
    if let Some(name) = english.filter(|name| is_new(&queries, name)) {
        queries.push(name.to_string());
    }
    let mut synonyms = 0;
    for synonym in media.synonyms.iter().map(|name| name.trim()) {
        if synonyms == MAX_SYNONYM_QUERIES {
            break;
        }
        if is_latin_title(synonym) && is_new(&queries, synonym) {
            queries.push(synonym.to_string());
            synonyms += 1;
        }
    }
    queries
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaId, MediaKind, MediaTitle};

    use super::*;

    fn media(romaji: &str, english: Option<&str>, synonyms: &[&str]) -> MediaSummary {
        let mut title = MediaTitle::new(romaji);
        title.english = english.map(str::to_string);
        let mut media = MediaSummary::new(MediaId::new(1).unwrap(), MediaKind::Manga, title);
        media.synonyms = synonyms.iter().map(|name| name.to_string()).collect();
        media
    }

    #[test]
    fn the_romaji_title_comes_first_then_the_english_one() {
        let queries = search_queries(&media("Kimi no Na wa.", Some("Your Name."), &[]));
        assert_eq!(queries, vec!["Kimi no Na wa.", "Your Name."]);
    }

    #[test]
    fn an_english_title_equal_to_the_romaji_is_not_asked_twice() {
        let queries = search_queries(&media("Naruto", Some("naruto"), &[]));
        assert_eq!(queries, vec!["Naruto"]);
    }

    #[test]
    fn a_blank_english_title_is_skipped() {
        let queries = search_queries(&media("Naruto", Some("   "), &[]));
        assert_eq!(queries, vec!["Naruto"]);
    }

    #[test]
    fn latin_synonyms_follow_in_the_order_they_were_given() {
        let queries = search_queries(&media(
            "Bireomeogeul Hwansaeng",
            Some("My Blasted Reincarnated Life"),
            &["Damn Reincarnation", "Reincarnation Without Damage"],
        ));
        assert_eq!(
            queries,
            vec![
                "Bireomeogeul Hwansaeng",
                "My Blasted Reincarnated Life",
                "Damn Reincarnation",
                "Reincarnation Without Damage",
            ]
        );
    }

    #[test]
    fn synonyms_in_other_scripts_are_not_searched() {
        let queries = search_queries(&media(
            "Mo Huang Da Guanjia",
            None,
            &[
                "三流反派的學院生存記",
                "จอมเขมือบกู้โลก",
                "ログイン武林",
                "Magic Emperor",
            ],
        ));
        assert_eq!(queries, vec!["Mo Huang Da Guanjia", "Magic Emperor"]);
    }

    #[test]
    fn titles_that_are_too_short_to_search_are_skipped() {
        let queries = search_queries(&media("One Piece", None, &["OP", "1", "  "]));
        assert_eq!(queries, vec!["One Piece"]);
    }

    #[test]
    fn a_synonym_repeating_an_earlier_title_in_other_case_is_dropped() {
        let queries = search_queries(&media("ONE PIECE", Some("One Piece"), &["one piece"]));
        assert_eq!(queries, vec!["ONE PIECE"]);
    }

    #[test]
    fn at_most_three_synonyms_are_added_so_the_search_stays_bounded() {
        let queries = search_queries(&media(
            "Main",
            Some("English"),
            &["Alias One", "Alias Two", "Alias Three", "Alias Four"],
        ));
        assert_eq!(queries.len(), 5);
        assert_eq!(queries.last().map(String::as_str), Some("Alias Three"));
    }

    #[test]
    fn vietnamese_and_accented_latin_titles_are_allowed() {
        let queries = search_queries(&media("Main", None, &["Vua Hải Tặc", "Café Étoilé"]));
        assert_eq!(queries, vec!["Main", "Vua Hải Tặc", "Café Étoilé"]);
    }
}
