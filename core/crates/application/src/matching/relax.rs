use super::dice::dice_coefficient;
use super::tokenize::tokenize;

fn offer(found: &mut Vec<String>, original: &str, candidate: String) {
    if !candidate.is_empty() && candidate != original && !found.contains(&candidate) {
        found.push(candidate);
    }
}

pub fn relaxed_queries(query: &str) -> Vec<String> {
    let words: Vec<&str> = query.split_whitespace().collect();
    let original = words.join(" ");
    let mut found = Vec::new();
    if words.len() > 2 {
        offer(&mut found, &original, words[..2].join(" "));
    }
    if words.len() > 1 {
        offer(&mut found, &original, words[..words.len() - 1].join(" "));
    }
    found
}

fn compact(text: &str) -> String {
    tokenize(text).concat()
}

pub fn loose_similarity(query: &str, title: &str) -> f64 {
    dice_coefficient(&compact(query), &compact(title))
}
