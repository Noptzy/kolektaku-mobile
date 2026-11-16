use domain::media::MediaSummary;

const MAX_SYNONYM_QUERIES: usize = 3;
const MIN_LETTERS: usize = 3;
const MAX_FRAGMENTS: usize = 3;
const MIN_FRAGMENT_LETTERS: usize = 5;
const NOISE_WORDS: [&str; 7] = ["movie", "season", "part", "film", "ova", "special", "tv"];
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

fn quiet(segment: &str) -> String {
    segment
        .split_whitespace()
        .filter(|word| {
            let lower = word.to_lowercase();
            !NOISE_WORDS.contains(&lower.as_str()) && !word.chars().all(|c| c.is_ascii_digit())
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn fragments_of(title: &str) -> Vec<String> {
    let segments: Vec<String> = title
        .split([':', '：'])
        .flat_map(|part| part.split(" - "))
        .map(|part| part.split_whitespace().collect::<Vec<_>>().join(" "))
        .filter(|part| !part.is_empty())
        .collect();
    if segments.len() < 2 {
        return Vec::new();
    }
    let tails = segments.iter().skip(1).rev().map(|part| quiet(part));
    let head = std::iter::once(segments[0].clone());
    tails
        .chain(head)
        .filter(|part| {
            part.chars().filter(|symbol| symbol.is_alphabetic()).count() >= MIN_FRAGMENT_LETTERS
        })
        .collect()
}

fn push_fragments(queries: &mut Vec<String>, title: &str, added: &mut usize) {
    for fragment in fragments_of(title) {
        if *added == MAX_FRAGMENTS {
            return;
        }
        if is_latin_title(&fragment) && is_new(queries, &fragment) {
            queries.push(fragment);
            *added += 1;
        }
    }
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
    let mut fragments = 0;
    push_fragments(&mut queries, &media.title.romaji, &mut fragments);
    if let Some(name) = english {
        push_fragments(&mut queries, name, &mut fragments);
    }
    queries
}
