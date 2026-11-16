use domain::media::MediaSummary;

const MAX_SYNONYM_QUERIES: usize = 3;
const MIN_LETTERS: usize = 3;
const PUNCTUATION: [char; 16] = [
    '[', ']', '(', ')', '{', '}', '【', '】', ':', '!', '?', ';', '~', '！', '？', '：',
];

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

fn without_punctuation(text: &str) -> Option<String> {
    if !text.contains(PUNCTUATION) {
        return None;
    }
    let plain = text
        .replace(PUNCTUATION, " ")
        .split_whitespace()
        .collect::<Vec<_>>()
        .join(" ");
    let letters = plain
        .chars()
        .filter(|symbol| symbol.is_alphabetic())
        .count();
    (letters >= MIN_LETTERS).then_some(plain)
}

fn push_title(queries: &mut Vec<String>, title: &str) -> bool {
    if !is_new(queries, title) {
        return false;
    }
    queries.push(title.to_string());
    if let Some(plain) = without_punctuation(title).filter(|plain| is_new(queries, plain)) {
        queries.push(plain);
    }
    true
}

pub fn search_queries(media: &MediaSummary) -> Vec<String> {
    let mut queries = Vec::new();
    push_title(&mut queries, &media.title.romaji);
    let english = media
        .title
        .english
        .as_deref()
        .map(str::trim)
        .filter(|name| !name.is_empty());
    if let Some(name) = english {
        push_title(&mut queries, name);
    }
    let mut synonyms = 0;
    for synonym in media.synonyms.iter().map(|name| name.trim()) {
        if synonyms == MAX_SYNONYM_QUERIES {
            break;
        }
        if is_latin_title(synonym) && push_title(&mut queries, synonym) {
            synonyms += 1;
        }
    }
    queries
}
