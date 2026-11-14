use std::sync::Arc;

use domain::media::{MediaKind, MediaListKind};

use super::search_test_support::anime;
use super::{HomeFeed, HomeSectionId};
use crate::ports::SourceProvider;
use crate::testing::{FakeCatalog, FakeClock, FakeSource};

pub(super) fn feed(
    catalog: FakeCatalog,
    sources: Vec<FakeSource>,
) -> (HomeFeed<FakeCatalog>, Vec<Arc<FakeSource>>) {
    let sources: Vec<Arc<FakeSource>> = sources.into_iter().map(Arc::new).collect();
    let providers: Vec<Arc<dyn SourceProvider>> = sources
        .iter()
        .map(|source| source.clone() as Arc<dyn SourceProvider>)
        .collect();
    (
        HomeFeed::new(Arc::new(catalog), providers, Arc::new(FakeClock::at(7))),
        sources,
    )
}

pub(super) fn full_catalog() -> FakeCatalog {
    FakeCatalog::new()
        .with_list(
            MediaKind::Anime,
            MediaListKind::Trending,
            vec![anime(1, "Alpha", &[]), anime(2, "Beta", &[])],
        )
        .with_list(
            MediaKind::Anime,
            MediaListKind::Seasonal,
            vec![anime(3, "Gamma", &[])],
        )
        .with_list(
            MediaKind::Anime,
            MediaListKind::Popular,
            vec![anime(4, "Delta", &[])],
        )
        .with_candidates(MediaKind::Anime, "Alpha", vec![anime(1, "Alpha", &[])])
}

pub(super) fn ids(outcome: &super::HomeOutcome) -> Vec<HomeSectionId> {
    outcome.sections.iter().map(|section| section.id).collect()
}
