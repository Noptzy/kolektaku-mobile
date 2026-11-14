use scraper::{ElementRef, Selector};
use url::Url;

pub fn selector(css: &str) -> Selector {
    Selector::parse(css).unwrap_or_else(|_| panic!("invalid selector {css}"))
}

pub fn collapse(text: &str) -> String {
    text.split_whitespace().collect::<Vec<_>>().join(" ")
}

pub fn text_of(element: ElementRef) -> String {
    element.text().collect()
}

pub fn text_excluding(element: ElementRef, tag: &str) -> String {
    element
        .descendants()
        .filter_map(|node| {
            let text = node.value().as_text()?;
            let excluded = node
                .ancestors()
                .take_while(|ancestor| ancestor.id() != element.id())
                .any(|ancestor| {
                    ancestor
                        .value()
                        .as_element()
                        .is_some_and(|inner| inner.name() == tag)
                });
            (!excluded).then(|| text.to_string())
        })
        .collect()
}

pub fn known_text(value: &str) -> Option<String> {
    let text = collapse(value);
    (!text.is_empty() && text != "?").then_some(text)
}

pub fn absolute_url(value: &str, base: &Url) -> Option<String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return None;
    }
    base.join(trimmed).ok().map(String::from)
}

pub fn first_number(label: &str) -> Option<f64> {
    let start = label.find(|character: char| character.is_ascii_digit())?;
    let rest = &label[start..];
    let whole = rest
        .find(|character: char| !character.is_ascii_digit())
        .unwrap_or(rest.len());
    let fraction = rest[whole..]
        .strip_prefix('.')
        .map(|after| {
            after
                .find(|character: char| !character.is_ascii_digit())
                .unwrap_or(after.len())
        })
        .filter(|digits| *digits > 0);
    let end = fraction.map_or(whole, |digits| whole + 1 + digits);
    rest[..end].parse().ok()
}

#[cfg(test)]
mod tests {
    use scraper::{Html, Selector};

    use super::*;

    #[test]
    fn collapse_squeezes_every_kind_of_whitespace() {
        assert_eq!(collapse("  a \n\t b\u{a0}c  "), "a b c");
        assert_eq!(collapse("   "), "");
    }

    #[test]
    fn known_text_treats_question_marks_and_blanks_as_unknown() {
        assert_eq!(known_text(" ? "), None);
        assert_eq!(known_text(" \n "), None);
        assert_eq!(known_text(" Ep  12 "), Some("Ep 12".into()));
    }

    #[test]
    fn absolute_url_resolves_against_the_base_and_skips_blanks() {
        let base = Url::parse("https://site.example/anime/").unwrap();
        assert_eq!(
            absolute_url("/poster.jpg", &base).as_deref(),
            Some("https://site.example/poster.jpg")
        );
        assert_eq!(
            absolute_url("https://img.example/a.jpg", &base).as_deref(),
            Some("https://img.example/a.jpg")
        );
        assert_eq!(absolute_url("  ", &base), None);
    }

    #[test]
    fn first_number_reads_whole_and_fractional_numbers() {
        assert_eq!(first_number("Episode 1145"), Some(1145.0));
        assert_eq!(first_number("Chapter 10.5 END"), Some(10.5));
        assert_eq!(first_number("Ep 12 / 24"), Some(12.0));
        assert_eq!(first_number("Ep 7."), Some(7.0));
        assert_eq!(first_number("no digits"), None);
    }

    #[test]
    fn text_excluding_skips_the_text_inside_the_named_tag_only() {
        let html = Html::parse_fragment("<p><b>Manga</b> Horor <i>x<b>y</b></i></p>");
        let paragraph = html.select(&Selector::parse("p").unwrap()).next().unwrap();
        assert_eq!(collapse(&text_excluding(paragraph, "b")), "Horor x");
    }

    #[test]
    fn text_of_joins_the_text_nodes_of_an_element() {
        let html = Html::parse_fragment("<p>a <b>b</b> c</p>");
        let paragraph = html.select(&Selector::parse("p").unwrap()).next().unwrap();
        assert_eq!(text_of(paragraph), "a b c");
    }
}
