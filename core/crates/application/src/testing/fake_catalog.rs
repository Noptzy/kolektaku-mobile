use std::collections::HashMap;

use domain::error::SourceError;
use domain::media::{
    Discover, EpisodeInfo, MediaDetail, MediaFormat, MediaId, MediaKind, MediaListKind, MediaPage,
    MediaSummary, Profile, ProfileKind, ProfileSummary,
};

use super::CallRecorder;
use crate::ports::MetadataCatalog;

#[derive(Default)]
pub struct FakeCatalog {
    pub(super) details: HashMap<MediaId, MediaDetail>,
    pub(super) lists: HashMap<(MediaKind, MediaListKind), Vec<MediaSummary>>,
    pub(super) searches: HashMap<(MediaKind, String), Vec<MediaSummary>>,
    pub(super) candidates: HashMap<(MediaKind, String), Vec<MediaSummary>>,
    pub(super) covers: HashMap<(MediaKind, String), Vec<String>>,
    pub(super) profiles: HashMap<(ProfileKind, u64), Profile>,
    pub(super) people: HashMap<(ProfileKind, String), Vec<ProfileSummary>>,
    pub(super) discovered: Vec<MediaSummary>,
    pub(super) titles: HashMap<MediaId, Vec<EpisodeInfo>>,
    pub(super) formats: HashMap<MediaId, MediaFormat>,
    pub(super) recorder: CallRecorder,
}

impl MetadataCatalog for FakeCatalog {
    async fn episode_titles(&self, detail: &MediaDetail) -> Vec<EpisodeInfo> {
        let _ = self.enter(format!("titles {}", detail.summary.id.get()));
        self.titles
            .get(&detail.summary.id)
            .cloned()
            .unwrap_or_else(|| detail.episodes.clone())
    }

    async fn detail(&self, kind: MediaKind, id: MediaId) -> Result<MediaDetail, SourceError> {
        self.enter(format!("detail {} {}", kind.as_str(), id.get()))?;
        self.details
            .get(&id)
            .cloned()
            .ok_or_else(|| SourceError::NotFound(id.get().to_string()))
    }

    async fn list(
        &self,
        kind: MediaKind,
        list: MediaListKind,
        page: u32,
    ) -> Result<MediaPage, SourceError> {
        self.enter(format!("list {} {:?} {page}", kind.as_str(), list))?;
        let items = self.lists.get(&(kind, list)).cloned().unwrap_or_default();
        Ok(MediaPage {
            items,
            page,
            has_next_page: false,
        })
    }

    async fn search(
        &self,
        kind: MediaKind,
        query: &str,
        page: u32,
    ) -> Result<MediaPage, SourceError> {
        self.enter(format!("search {} {query}", kind.as_str()))?;
        let items = self
            .searches
            .get(&(kind, query.to_string()))
            .cloned()
            .unwrap_or_default();
        Ok(MediaPage {
            items,
            page,
            has_next_page: false,
        })
    }

    async fn match_titles(
        &self,
        kind: MediaKind,
        titles: &[String],
    ) -> Result<Vec<Vec<MediaSummary>>, SourceError> {
        self.enter(format!("match_titles {} {}", kind.as_str(), titles.len()))?;
        Ok(titles
            .iter()
            .map(|title| {
                self.candidates
                    .get(&(kind, title.clone()))
                    .cloned()
                    .unwrap_or_default()
            })
            .collect())
    }

    async fn genre_covers(
        &self,
        kind: MediaKind,
        genres: &[String],
    ) -> Result<Vec<Vec<String>>, SourceError> {
        self.enter(format!("genre_covers {} {}", kind.as_str(), genres.len()))?;
        Ok(genres
            .iter()
            .map(|genre| {
                self.covers
                    .get(&(kind, genre.clone()))
                    .cloned()
                    .unwrap_or_default()
            })
            .collect())
    }

    async fn profile(&self, kind: ProfileKind, id: u64) -> Result<Profile, SourceError> {
        self.enter(format!("profile {kind:?} {id}"))?;
        self.profiles
            .get(&(kind, id))
            .cloned()
            .ok_or_else(|| SourceError::NotFound(id.to_string()))
    }

    async fn search_profiles(
        &self,
        kind: ProfileKind,
        query: &str,
    ) -> Result<Vec<ProfileSummary>, SourceError> {
        self.enter(format!("search_profiles {kind:?} {query}"))?;
        Ok(self
            .people
            .get(&(kind, query.to_string()))
            .cloned()
            .unwrap_or_default())
    }

    async fn discover(
        &self,
        kind: MediaKind,
        filter: &Discover,
        page: u32,
    ) -> Result<MediaPage, SourceError> {
        self.enter(format!("discover {} {filter:?} {page}", kind.as_str()))?;
        Ok(MediaPage {
            items: self.discovered.clone(),
            page,
            has_next_page: false,
        })
    }

    async fn comic_formats(
        &self,
        ids: &[MediaId],
    ) -> Result<Vec<(MediaId, Option<MediaFormat>)>, SourceError> {
        self.enter(format!("comic_formats {}", ids.len()))?;
        Ok(ids
            .iter()
            .filter(|id| self.formats.contains_key(id))
            .map(|id| (*id, self.formats.get(id).copied()))
            .collect())
    }
}
