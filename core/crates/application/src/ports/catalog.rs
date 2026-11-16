use std::future::Future;

use domain::error::SourceError;
use domain::media::{
    Discover, EpisodeInfo, MediaDetail, MediaFormat, MediaId, MediaKind, MediaListKind, MediaPage,
    MediaSummary, Profile, ProfileKind, ProfileSummary,
};

pub trait MetadataCatalog: Send + Sync {
    fn detail(
        &self,
        kind: MediaKind,
        id: MediaId,
    ) -> impl Future<Output = Result<MediaDetail, SourceError>> + Send;

    fn detail_fast(
        &self,
        kind: MediaKind,
        id: MediaId,
    ) -> impl Future<Output = Result<MediaDetail, SourceError>> + Send {
        self.detail(kind, id)
    }

    fn episode_titles(
        &self,
        detail: &MediaDetail,
    ) -> impl Future<Output = Vec<EpisodeInfo>> + Send {
        let episodes = detail.episodes.clone();
        async move { episodes }
    }

    fn list(
        &self,
        kind: MediaKind,
        list: MediaListKind,
        page: u32,
    ) -> impl Future<Output = Result<MediaPage, SourceError>> + Send;

    fn search(
        &self,
        kind: MediaKind,
        query: &str,
        page: u32,
    ) -> impl Future<Output = Result<MediaPage, SourceError>> + Send;

    fn match_titles(
        &self,
        kind: MediaKind,
        titles: &[String],
    ) -> impl Future<Output = Result<Vec<Vec<MediaSummary>>, SourceError>> + Send;

    fn genre_covers(
        &self,
        kind: MediaKind,
        genres: &[String],
    ) -> impl Future<Output = Result<Vec<Vec<String>>, SourceError>> + Send;

    fn profile(
        &self,
        kind: ProfileKind,
        id: u64,
    ) -> impl Future<Output = Result<Profile, SourceError>> + Send;

    fn search_profiles(
        &self,
        kind: ProfileKind,
        query: &str,
    ) -> impl Future<Output = Result<Vec<ProfileSummary>, SourceError>> + Send;

    fn discover(
        &self,
        kind: MediaKind,
        filter: &Discover,
        page: u32,
    ) -> impl Future<Output = Result<MediaPage, SourceError>> + Send;

    fn comic_formats(
        &self,
        ids: &[MediaId],
    ) -> impl Future<Output = Result<Vec<(MediaId, Option<MediaFormat>)>, SourceError>> + Send;
}
