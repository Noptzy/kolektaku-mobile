use std::sync::Arc;

use domain::translation::LanguageRoute;

use super::prepare_cue::{CueShape, prepare_cue};
use super::translate_lines::TranslateLines;
use crate::ports::Translator;
use crate::streaming::Cue;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CueTranslation {
    pub cues: Vec<Cue>,
    pub translated: bool,
    pub failed: bool,
}

pub struct TranslateCues {
    lines: TranslateLines,
}

struct Prepared {
    shapes: Vec<CueShape>,
    to_send: Vec<String>,
    start_at: usize,
}

impl TranslateCues {
    pub fn new(translator: Arc<dyn Translator>) -> Self {
        Self {
            lines: TranslateLines::new(translator),
        }
    }

    pub async fn execute(
        &self,
        cues: Vec<Cue>,
        route: &LanguageRoute,
        position_ms: u64,
    ) -> CueTranslation {
        let prepared = prepare(&cues, position_ms);
        let outcome = self
            .lines
            .execute(prepared.to_send, route, prepared.start_at)
            .await;
        if !outcome.translated {
            return CueTranslation {
                cues,
                translated: false,
                failed: outcome.failed,
            };
        }
        CueTranslation {
            cues: rebuild(cues, prepared.shapes, outcome.lines),
            translated: true,
            failed: outcome.failed,
        }
    }
}

fn prepare(cues: &[Cue], position_ms: u64) -> Prepared {
    let mut shapes = Vec::with_capacity(cues.len());
    let mut to_send = Vec::new();
    let mut start_at = None;
    for cue in cues {
        let shape = prepare_cue(&cue.text);
        if start_at.is_none() && cue.end_ms > position_ms {
            start_at = Some(to_send.len());
        }
        match &shape {
            CueShape::Merged(text) => to_send.push(text.clone()),
            CueShape::Dialogue(lines) => to_send.extend(lines.iter().cloned()),
            CueShape::Kept => {}
        }
        shapes.push(shape);
    }
    Prepared {
        shapes,
        to_send,
        start_at: start_at.unwrap_or(0),
    }
}

fn rebuild(cues: Vec<Cue>, shapes: Vec<CueShape>, answered: Vec<String>) -> Vec<Cue> {
    let mut answers = answered.into_iter();
    cues.into_iter()
        .zip(shapes)
        .map(|(cue, shape)| {
            let text = match shape {
                CueShape::Merged(_) => answers.next().unwrap_or(cue.text),
                CueShape::Dialogue(lines) => lines
                    .iter()
                    .filter_map(|_| answers.next())
                    .collect::<Vec<_>>()
                    .join("\n"),
                CueShape::Kept => cue.text,
            };
            Cue { text, ..cue }
        })
        .collect()
}
