use domain::media::MediaFormat;

use super::normalize::normalize_title;
use super::target::MatchTarget;

const MIN_LETTERS: usize = 5;
const WEB_NOVEL_FACTOR: f64 = 0.9;
const SUBTITLE_MARKS: [char; 5] = [':', '-', '~', '\u{2013}', '\u{ff1a}'];
const NOISE_PHRASES: [&str; 5] = [
    "light novel",
    "web novel",
    "bahasa indonesia",
    "novel",
    "indonesia",
];
const NOISE_WORDS: [&str; 2] = ["ln", "wn"];

pub fn is_novel_target(target: &MatchTarget) -> bool {
    target.format == Some(MediaFormat::Novel)
}

fn strip_trailing_noise(text: &str) -> String {
    let opened = text.replace(['(', ')', '[', ']'], " ");
    let mut words: Vec<String> = opened.split_whitespace().map(str::to_string).collect();
    loop {
        let lower = words.join(" ").to_lowercase();
        let phrase = NOISE_PHRASES
            .iter()
            .find(|phrase| lower.ends_with(*phrase) && lower.len() > phrase.len());
        if let Some(phrase) = phrase {
            let keep = words.len() - phrase.split(' ').count();
            words.truncate(keep);
            continue;
        }
        let last_is_mark = words
            .last()
            .is_some_and(|word| NOISE_WORDS.contains(&word.to_lowercase().as_str()));
        if last_is_mark && words.len() > 1 {
            words.pop();
            continue;
        }
        return words.join(" ");
    }
}

fn is_prefix_of(short: &[String], long: &[String]) -> bool {
    short.len() < long.len() && long[..short.len()] == *short
}

fn folded(tokens: &[String]) -> Vec<String> {
    tokens
        .iter()
        .map(|token| {
            if token == "wo" {
                "o".to_string()
            } else {
                token.clone()
            }
        })
        .collect()
}

fn is_short_main_title(wanted: &str, target: &str) -> bool {
    let letters = wanted.chars().filter(|c| c.is_alphabetic()).count();
    let has_digit = wanted.chars().any(|c| c.is_ascii_digit());
    if wanted.chars().count() < 2 || !(letters >= 3 || has_digit) {
        return false;
    }
    let lower = target.to_lowercase();
    lower
        .strip_prefix(&wanted.to_lowercase())
        .is_some_and(|rest| rest.trim_start().starts_with(SUBTITLE_MARKS))
}

pub fn is_novel_title_of(targets: &[String], candidate: &str) -> bool {
    let cleaned = strip_trailing_noise(candidate);
    let wanted = normalize_title(&cleaned);
    let wanted_tokens = folded(&wanted.tokens);
    if wanted_tokens.is_empty() {
        return false;
    }
    let letters = wanted.text.chars().filter(|c| c.is_alphanumeric()).count();
    targets.iter().any(|target| {
        let known_tokens = folded(&normalize_title(target).tokens);
        if known_tokens == wanted_tokens {
            return letters >= MIN_LETTERS;
        }
        if !is_prefix_of(&wanted_tokens, &known_tokens) {
            return false;
        }
        letters >= MIN_LETTERS || is_short_main_title(cleaned.trim(), target)
    })
}

pub fn novel_title_score(titles: &[String], candidates: &[String]) -> f64 {
    let same = candidates
        .iter()
        .any(|candidate| is_novel_title_of(titles, candidate));
    if same { 1.0 } else { 0.0 }
}

pub fn edition_factor(type_text: Option<&str>) -> f64 {
    let is_web = type_text.is_some_and(|text| text.to_lowercase().contains("web novel"));
    if is_web { WEB_NOVEL_FACTOR } else { 1.0 }
}
