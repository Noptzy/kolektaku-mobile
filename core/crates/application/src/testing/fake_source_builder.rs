use domain::error::SourceError;
use domain::source::{ItemId, SourceDetail, SourceItem, StreamSupport, Unit};

use super::fake_source::normalize;
use super::{FakeGenres, FakePages, FakeSource, FakeText, FakeVideo};

impl FakeSource {
    pub fn with_priority(mut self, priority: u8) -> Self {
        self.info.priority = priority;
        self
    }

    pub fn with_search(mut self, query: &str, items: Vec<SourceItem>) -> Self {
        self.searches.insert(normalize(query), items);
        self
    }

    pub fn with_latest(mut self, items: Vec<SourceItem>) -> Self {
        self.latest = items;
        self
    }

    pub fn with_detail(mut self, detail: SourceDetail) -> Self {
        self.details.insert(detail.item.item_id.clone(), detail);
        self
    }

    pub fn with_units(mut self, item: &str, units: Vec<Unit>) -> Self {
        self.units.insert(ItemId::new(item), units);
        self
    }

    pub fn with_video(mut self, video: FakeVideo) -> Self {
        self.info.capabilities.stream = StreamSupport::Direct;
        self.video = Some(video);
        self
    }

    pub fn with_pages(mut self, pages: FakePages) -> Self {
        self.pages = Some(pages);
        self
    }

    pub fn with_text(mut self, text: FakeText) -> Self {
        self.text = Some(text);
        self
    }

    pub fn failing_with(self, error: SourceError) -> Self {
        self.set_failure(Some(error));
        self
    }

    pub fn set_failure(&self, error: Option<SourceError>) {
        self.recorder.set_failure(error);
    }

    pub fn calls(&self) -> Vec<String> {
        self.recorder.calls()
    }

    pub fn with_genres(mut self, genres: FakeGenres) -> Self {
        self.genres = Some(genres);
        self
    }
}
