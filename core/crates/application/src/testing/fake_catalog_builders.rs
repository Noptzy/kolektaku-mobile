use domain::error::SourceError;
use domain::media::{
    EpisodeInfo, MediaDetail, MediaFormat, MediaId, MediaKind, MediaListKind, MediaSummary,
    Profile, ProfileKind, ProfileSummary,
};

use super::fake_catalog::FakeCatalog;

impl FakeCatalog {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_detail(mut self, detail: MediaDetail) -> Self {
        self.details.insert(detail.summary.id, detail);
        self
    }

    pub fn with_format(mut self, id: MediaId, format: MediaFormat) -> Self {
        self.formats.insert(id, format);
        self
    }

    pub fn with_episode_titles(mut self, id: MediaId, titles: Vec<EpisodeInfo>) -> Self {
        self.titles.insert(id, titles);
        self
    }

    pub fn with_list(
        mut self,
        kind: MediaKind,
        list: MediaListKind,
        items: Vec<MediaSummary>,
    ) -> Self {
        self.lists.insert((kind, list), items);
        self
    }

    pub fn with_search(mut self, kind: MediaKind, query: &str, items: Vec<MediaSummary>) -> Self {
        self.searches.insert((kind, query.to_string()), items);
        self
    }

    pub fn with_candidates(
        mut self,
        kind: MediaKind,
        title: &str,
        items: Vec<MediaSummary>,
    ) -> Self {
        self.candidates.insert((kind, title.to_string()), items);
        self
    }

    pub fn with_covers(mut self, kind: MediaKind, genre: &str, urls: &[&str]) -> Self {
        let urls = urls.iter().map(ToString::to_string).collect();
        self.covers.insert((kind, genre.to_string()), urls);
        self
    }

    pub fn with_profile(mut self, kind: ProfileKind, profile: Profile) -> Self {
        self.profiles.insert((kind, profile.id), profile);
        self
    }

    pub fn with_people(
        mut self,
        kind: ProfileKind,
        query: &str,
        found: Vec<ProfileSummary>,
    ) -> Self {
        self.people.insert((kind, query.to_string()), found);
        self
    }

    pub fn with_discovered(mut self, items: Vec<MediaSummary>) -> Self {
        self.discovered = items;
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

    pub(super) fn enter(&self, call: String) -> Result<(), SourceError> {
        self.recorder.enter(call)
    }
}
