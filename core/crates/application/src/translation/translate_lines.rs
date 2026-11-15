use std::collections::HashMap;
use std::sync::Arc;

use domain::translation::{LanguageRoute, speaks_the_same};

use super::chunks::{BYTES_PER_REQUEST, LINES_PER_REQUEST, chunk_by_limits};
use crate::ports::Translator;

pub const MAX_REQUESTS_PER_FILE: usize = 12;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LineTranslation {
    pub lines: Vec<String>,
    pub translated: bool,
    pub failed: bool,
    pub requests: usize,
    pub detected_from: Option<String>,
}

impl LineTranslation {
    fn untouched(lines: Vec<String>) -> Self {
        Self {
            lines,
            translated: false,
            failed: false,
            requests: 0,
            detected_from: None,
        }
    }
}

pub struct TranslateLines {
    translator: Arc<dyn Translator>,
}

impl TranslateLines {
    pub fn new(translator: Arc<dyn Translator>) -> Self {
        Self { translator }
    }

    pub async fn execute(
        &self,
        lines: Vec<String>,
        route: &LanguageRoute,
        start_at: usize,
    ) -> LineTranslation {
        if route.needs_no_translation() {
            return LineTranslation::untouched(lines);
        }
        let unique = unique_texts_from(&lines, start_at);
        let chunks = chunk_by_limits(&unique, LINES_PER_REQUEST, BYTES_PER_REQUEST);
        let mut outcome = LineTranslation::untouched(Vec::new());
        let mut known: HashMap<String, String> = HashMap::new();
        for range in chunks.into_iter().take(MAX_REQUESTS_PER_FILE) {
            let asked = unique[range].to_vec();
            outcome.requests += 1;
            match self
                .translator
                .translate(asked.clone(), route.clone())
                .await
            {
                Ok(reply) if reply.answers(asked.len()) => {
                    outcome.translated = true;
                    outcome.detected_from = outcome.detected_from.or(reply.detected_from.clone());
                    keep_usable(&mut known, asked, reply.lines);
                }
                Ok(_) => {}
                Err(_) => {
                    outcome.failed = true;
                    break;
                }
            }
        }
        finish(lines, known, route, outcome)
    }
}

fn unique_texts_from(lines: &[String], start_at: usize) -> Vec<String> {
    let start = start_at.min(lines.len());
    let mut seen: HashMap<&str, ()> = HashMap::new();
    let mut unique = Vec::new();
    for line in lines[start..].iter().chain(lines[..start].iter()) {
        if !line.trim().is_empty() && seen.insert(line.as_str(), ()).is_none() {
            unique.push(line.clone());
        }
    }
    unique
}

fn keep_usable(known: &mut HashMap<String, String>, asked: Vec<String>, answered: Vec<String>) {
    for (original, translation) in asked.into_iter().zip(answered) {
        if !translation.trim().is_empty() {
            known.insert(original, translation);
        }
    }
}

fn finish(
    lines: Vec<String>,
    known: HashMap<String, String>,
    route: &LanguageRoute,
    mut outcome: LineTranslation,
) -> LineTranslation {
    let already_in_target = outcome
        .detected_from
        .as_deref()
        .is_some_and(|detected| speaks_the_same(detected, route.target_code()));
    if already_in_target {
        outcome.translated = false;
        outcome.lines = lines;
        return outcome;
    }
    outcome.lines = lines
        .into_iter()
        .map(|line| known.get(&line).cloned().unwrap_or(line))
        .collect();
    outcome
}
