use std::cmp::Ordering;
use std::sync::Arc;

use domain::error::SourceError;
use domain::scene::SceneMatch;

use crate::ports::SceneSearch;

pub const DIRECT_SIMILARITY: f32 = 0.90;
pub const CANDIDATE_SIMILARITY: f32 = 0.80;
pub const MAX_CANDIDATES: usize = 5;

#[derive(Debug, Clone, PartialEq)]
pub enum SceneOutcome {
    Direct {
        best: SceneMatch,
        others: Vec<SceneMatch>,
    },
    Candidates(Vec<SceneMatch>),
    NotFound,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SceneFinding {
    pub outcome: SceneOutcome,
    pub quota_left: Option<u32>,
}

pub struct FindScene<S: SceneSearch> {
    search: Arc<S>,
}

impl<S: SceneSearch> FindScene<S> {
    pub fn new(search: Arc<S>) -> Self {
        Self { search }
    }

    pub async fn quota_left(&self) -> Option<u32> {
        self.search.quota_left().await.ok()
    }

    pub async fn execute(&self, image: Vec<u8>) -> Result<SceneFinding, SourceError> {
        let reply = self.search.find(image).await?;
        Ok(SceneFinding {
            outcome: classify(reply.matches),
            quota_left: reply.quota_left,
        })
    }
}

fn by_similarity(a: &SceneMatch, b: &SceneMatch) -> Ordering {
    b.similarity
        .partial_cmp(&a.similarity)
        .unwrap_or(Ordering::Equal)
}

fn same_scene(a: &SceneMatch, b: &SceneMatch) -> bool {
    a.media_id == b.media_id && a.episode == b.episode
}

fn distinct_scenes(sorted: Vec<SceneMatch>) -> Vec<SceneMatch> {
    let mut kept: Vec<SceneMatch> = Vec::new();
    for candidate in sorted {
        if !kept.iter().any(|existing| same_scene(existing, &candidate)) {
            kept.push(candidate);
        }
    }
    kept
}

fn classify(matches: Vec<SceneMatch>) -> SceneOutcome {
    let mut plausible: Vec<SceneMatch> = matches
        .into_iter()
        .filter(|found| !found.is_adult && found.similarity >= CANDIDATE_SIMILARITY)
        .collect();
    plausible.sort_by(by_similarity);
    let mut kept = distinct_scenes(plausible);
    match kept.first() {
        None => SceneOutcome::NotFound,
        Some(top) if top.similarity >= DIRECT_SIMILARITY => {
            let best = kept.remove(0);
            kept.truncate(MAX_CANDIDATES - 1);
            SceneOutcome::Direct { best, others: kept }
        }
        Some(_) => {
            kept.truncate(MAX_CANDIDATES);
            SceneOutcome::Candidates(kept)
        }
    }
}
