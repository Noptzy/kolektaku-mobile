use std::sync::Arc;

use domain::media::{
    MediaFormat, MediaId, MediaKind, MediaRef, MediaStatus, MediaSummary, MediaTitle,
};
use domain::source::{ItemId, SourceDetail, SourceItem};

use super::{ResolveSources, SourceHealth};
use crate::ports::SourceProvider;
use crate::testing::{FakeClock, FakeSource, MemoryLinkStore};

pub const TITLE: &str = "Spy x Family";
pub const DAY: u64 = 24 * 60 * 60;

pub fn media() -> MediaSummary {
    let mut media = MediaSummary::new(
        MediaId::new(140960).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(TITLE),
    );
    media.format = Some(MediaFormat::Tv);
    media.year = Some(2022);
    media.unit_count = Some(12);
    media.status = Some(MediaStatus::Finished);
    media
}

pub fn reference() -> MediaRef {
    MediaRef::catalog(media().id)
}

pub fn detail(item: &str, title: &str, year: u16, units: u32) -> SourceDetail {
    let mut detail = SourceDetail::new(SourceItem::new(ItemId::new(item), title));
    detail.type_text = Some("TV".into());
    detail.year = Some(year);
    detail.unit_count = Some(units);
    detail
}

pub fn site_with(id: &str, priority: u8, item: &str, year: u16, units: u32) -> FakeSource {
    FakeSource::new(id, MediaKind::Anime)
        .with_priority(priority)
        .with_search(TITLE, vec![SourceItem::new(ItemId::new(item), TITLE)])
        .with_detail(detail(item, TITLE, year, units))
}

pub fn empty_site(id: &str, priority: u8) -> FakeSource {
    FakeSource::new(id, MediaKind::Anime).with_priority(priority)
}

pub struct Rig {
    pub sources: Vec<Arc<FakeSource>>,
    pub store: Arc<MemoryLinkStore>,
    pub clock: Arc<FakeClock>,
    pub health: Arc<SourceHealth>,
    pub use_case: ResolveSources<MemoryLinkStore>,
}

pub fn rig(sources: Vec<FakeSource>) -> Rig {
    let sources: Vec<Arc<FakeSource>> = sources.into_iter().map(Arc::new).collect();
    let providers: Vec<Arc<dyn SourceProvider>> = sources
        .iter()
        .map(|source| source.clone() as Arc<dyn SourceProvider>)
        .collect();
    let store = Arc::new(MemoryLinkStore::new());
    let clock = Arc::new(FakeClock::at(10 * DAY));
    let health = Arc::new(SourceHealth::new(clock.clone()));
    let use_case = ResolveSources::new(providers, store.clone(), health.clone(), clock.clone());
    Rig {
        sources,
        store,
        clock,
        health,
        use_case,
    }
}

impl Rig {
    pub fn clock_now(&self) -> u64 {
        use crate::ports::Clock;
        self.clock.now_secs()
    }
}

pub fn order(links: &[domain::source::SourceLink]) -> Vec<&str> {
    links.iter().map(|link| link.source.as_str()).collect()
}
