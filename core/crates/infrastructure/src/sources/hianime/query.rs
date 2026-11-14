const MIN_LENGTH: usize = 3;
const SHORT_PREFIXES: [usize; 2] = [3, 2];

fn collapse(text: &str) -> String {
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn head_of(text: &str) -> String {
    let cut = [" - ", ":", " (", "~"]
        .iter()
        .filter_map(|marker| text.find(marker))
        .min()
        .unwrap_or(text.len());
    collapse(&text[..cut])
}

pub fn query_variants(query: &str) -> Vec<String> {
    let full = collapse(query);
    let mut variants = vec![full.clone(), head_of(&full)];
    let words: Vec<&str> = full.split_whitespace().collect();
    for count in SHORT_PREFIXES {
        if words.len() > count {
            variants.push(words[..count].join(" "));
        }
    }
    let mut unique: Vec<String> = Vec::new();
    for (index, variant) in variants.into_iter().enumerate() {
        let wanted = index == 0 || variant.chars().count() >= MIN_LENGTH;
        let known = unique.iter().any(|known| known.eq_ignore_ascii_case(&variant));
        if wanted && !variant.is_empty() && !known {
            unique.push(variant);
        }
    }
    unique
}

pub fn filter_body(keyword: &str, page: u32) -> String {
    serde_json::json!({ "page": page.max(1), "limit": 20, "keyword": keyword }).to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_full_query_always_comes_first() {
        assert_eq!(query_variants("one piece")[0], "one piece");
    }

    #[test]
    fn a_long_title_is_shortened_step_by_step() {
        assert_eq!(
            query_variants("STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE"),
            [
                "STEEL BALL RUN JoJo's Bizarre Adventure 2nd - 3rd STAGE",
                "STEEL BALL RUN JoJo's Bizarre Adventure 2nd",
                "STEEL BALL RUN",
                "STEEL BALL",
            ]
        );
    }

    #[test]
    fn a_subtitle_after_a_colon_is_cut_off() {
        let variants = query_variants("JoJo no Kimyou na Bouken: Steel Ball Run");
        assert_eq!(variants[1], "JoJo no Kimyou na Bouken");
    }

    #[test]
    fn a_parenthetical_is_cut_off() {
        let variants = query_variants("Kimetsu no Yaiba (Season 2)");
        assert_eq!(variants[1], "Kimetsu no Yaiba");
    }

    #[test]
    fn short_or_duplicate_variants_are_not_repeated() {
        assert_eq!(query_variants("naruto"), ["naruto"]);
        assert_eq!(query_variants("a b"), ["a b"]);
        assert!(query_variants("  ").is_empty());
    }

    #[test]
    fn a_very_short_query_is_still_sent_as_it_is() {
        assert_eq!(query_variants("ab"), ["ab"]);
        assert_eq!(query_variants("x"), ["x"]);
        assert_eq!(query_variants("a bc de f"), ["a bc de f", "a bc de", "a bc"]);
    }

    #[test]
    fn spaces_are_collapsed() {
        assert_eq!(query_variants("  one    piece  ")[0], "one piece");
    }

    #[test]
    fn the_filter_body_names_page_limit_and_keyword() {
        let body: serde_json::Value = serde_json::from_str(&filter_body("jojo", 2)).unwrap();
        assert_eq!(body["keyword"], "jojo");
        assert_eq!(body["page"], 2);
        assert_eq!(body["limit"], 20);
        let first: serde_json::Value = serde_json::from_str(&filter_body("x", 0)).unwrap();
        assert_eq!(first["page"], 1);
    }

    #[test]
    fn a_keyword_with_quotes_stays_valid_json() {
        let body = filter_body("say \"hi\" \\ there", 1);
        let parsed: serde_json::Value = serde_json::from_str(&body).unwrap();
        assert_eq!(parsed["keyword"], "say \"hi\" \\ there");
    }
}
