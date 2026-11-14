use std::sync::Arc;

use domain::media::{MediaId, MediaKind, MediaSummary, MediaTitle};
use domain::source::{ItemId, SourceItem};

use super::SearchMedia;
use crate::ports::SourceProvider;
use crate::testing::{FakeCatalog, FakeClock, FakeSource};

pub fn anime(id: u64, romaji: &str, synonyms: &[&str]) -> MediaSummary {
    let mut summary = MediaSummary::new(
        MediaId::new(id).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(romaji),
    );
    summary.synonyms = synonyms.iter().map(|name| name.to_string()).collect();
    summary
}

pub fn item(id: &str, title: &str) -> SourceItem {
    SourceItem::new(ItemId::new(id), title)
}

pub fn source(id: &str) -> FakeSource {
    FakeSource::new(id, MediaKind::Anime)
}

pub struct Harness {
    pub catalog: Arc<FakeCatalog>,
    pub sources: Vec<Arc<FakeSource>>,
    pub use_case: SearchMedia<FakeCatalog>,
}

pub fn harness(catalog: FakeCatalog, sources: Vec<FakeSource>) -> Harness {
    let catalog = Arc::new(catalog);
    let sources: Vec<Arc<FakeSource>> = sources.into_iter().map(Arc::new).collect();
    let providers: Vec<Arc<dyn SourceProvider>> = sources
        .iter()
        .map(|source| source.clone() as Arc<dyn SourceProvider>)
        .collect();
    let use_case = SearchMedia::new(catalog.clone(), providers, Arc::new(FakeClock::at(1_000)));
    Harness {
        catalog,
        sources,
        use_case,
    }
}
