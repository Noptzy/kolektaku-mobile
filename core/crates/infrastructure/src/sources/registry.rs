use std::sync::Arc;

use application::ports::{Clock, SourceProvider};
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::SourceId;

use crate::config::{Defaults, SourceSettings};
use crate::http::HttpClient;

pub struct SourceEnv {
    pub http: Arc<dyn HttpClient>,
    pub clock: Arc<dyn Clock>,
}

pub type SourceBuilder =
    fn(&SourceEnv, &SourceSettings) -> Result<Arc<dyn SourceProvider>, SourceError>;

pub struct Registration {
    pub defaults: Defaults,
    pub build: SourceBuilder,
    #[cfg(test)]
    pub contract: fn() -> crate::sources::contract::ContractSite,
}

macro_rules! sources {
    ($($(#[$meta:meta])* $name:ident => $path:literal),* $(,)?) => {
        $($(#[$meta])* #[path = $path] pub mod $name;)*

        pub const REGISTRATIONS: &[&Registration] = &[$($(#[$meta])* &$name::REGISTRATION),*];
    };
}

sources! {
    bakatsuki => "bakatsuki/mod.rs",
    kuramanime => "kuramanime/mod.rs",
    gogoanime => "gogoanime/mod.rs",
    hianime => "hianime/mod.rs",
    komiku => "komiku/mod.rs",
    komikindo => "komikindo/mod.rs",
    meionovels => "meionovels/mod.rs",
    novelphoenix => "novelphoenix/mod.rs",
    weebcentral => "weebcentral/mod.rs",
    #[cfg(test)] example => "example/mod.rs",
}

pub fn all_defaults() -> Vec<Defaults> {
    REGISTRATIONS
        .iter()
        .map(|registration| registration.defaults)
        .collect()
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BuildProblem {
    pub id: String,
    pub error: SourceError,
}

pub struct SourceRegistry {
    sources: Vec<Arc<dyn SourceProvider>>,
    problems: Vec<BuildProblem>,
}

impl SourceRegistry {
    pub fn build(env: &SourceEnv, settings: &[SourceSettings]) -> Self {
        let mut sources = Vec::new();
        let mut problems = Vec::new();
        for entry in settings.iter().filter(|entry| entry.enabled) {
            let built = REGISTRATIONS
                .iter()
                .find(|registration| registration.defaults.id == entry.id)
                .ok_or_else(|| SourceError::Unsupported(format!("unknown source {}", entry.id)))
                .and_then(|registration| (registration.build)(env, entry));
            match built {
                Ok(source) => sources.push(source),
                Err(error) => problems.push(BuildProblem {
                    id: entry.id.clone(),
                    error,
                }),
            }
        }
        Self { sources, problems }
    }

    pub fn from_providers(sources: Vec<Arc<dyn SourceProvider>>) -> Self {
        Self {
            sources,
            problems: Vec::new(),
        }
    }

    pub fn all(&self) -> Vec<Arc<dyn SourceProvider>> {
        self.sources.clone()
    }

    pub fn for_kind(&self, kind: MediaKind) -> Vec<Arc<dyn SourceProvider>> {
        let mut matching: Vec<Arc<dyn SourceProvider>> = self
            .sources
            .iter()
            .filter(|source| source.info().kind == kind)
            .cloned()
            .collect();
        matching.sort_by_key(|source| (source.info().priority, source.info().id.clone()));
        matching
    }

    pub fn get(&self, id: &SourceId) -> Option<Arc<dyn SourceProvider>> {
        self.sources
            .iter()
            .find(|source| source.info().id == *id)
            .cloned()
    }

    pub fn problems(&self) -> &[BuildProblem] {
        &self.problems
    }
}
