use std::sync::Arc;

use application::ports::{Clock, MetadataCatalog};
use domain::error::SourceError;
use domain::media::{
    Discover, EpisodeInfo, MediaDetail, MediaId, MediaKind, MediaListKind, MediaPage, MediaSummary,
    Profile, ProfileKind, ProfileSummary,
};
use serde::de::DeserializeOwned;
use serde_json::{Value, json};

use super::covers::fetch_covers;
use super::discover::discover_variables;
use super::graphql::GraphQl;
use super::mapper::{map_detail, visible_summaries};
use super::matching::match_all;
use super::profile_fetch::{fetch_people, fetch_profile};
use super::queries::{detail_query, discover_query, list_query, search_query};
use super::schema::{RawDetailResponse, RawListResponse};
use super::season::season_of;
use crate::catalog::mal::titled_episodes;
use crate::http::HttpClient;

const ENDPOINT: &str = "https://graphql.anilist.co";
const PAGE_SIZE: u32 = 20;
const ANIME_COUNTRY: &str = "JP";

pub struct AniListCatalog {
    graphql: GraphQl,
    http: Arc<dyn HttpClient>,
    clock: Arc<dyn Clock>,
}

impl AniListCatalog {
    pub fn new(http: Arc<dyn HttpClient>, clock: Arc<dyn Clock>) -> Self {
        Self {
            graphql: GraphQl::new(http.clone(), ENDPOINT),
            http,
            clock,
        }
    }

    async fn page(
        &self,
        query: String,
        variables: Value,
        requested: u32,
    ) -> Result<MediaPage, SourceError> {
        let data = self.graphql.run(&query, variables).await?;
        let response: RawListResponse = parse(data, "list")?;
        let info = response.page.page_info;
        Ok(MediaPage {
            items: visible_summaries(response.page.media),
            page: info
                .as_ref()
                .and_then(|info| info.current_page)
                .unwrap_or(requested),
            has_next_page: info.and_then(|info| info.has_next_page).unwrap_or(false),
        })
    }
}

pub(super) fn media_type(kind: MediaKind) -> &'static str {
    match kind {
        MediaKind::Anime => "ANIME",
        MediaKind::Manga => "MANGA",
    }
}

fn sorts(list: MediaListKind) -> Vec<&'static str> {
    match list {
        MediaListKind::Trending => vec!["TRENDING_DESC", "POPULARITY_DESC"],
        MediaListKind::Popular | MediaListKind::Seasonal => vec!["POPULARITY_DESC"],
    }
}

pub(super) fn parse<T: DeserializeOwned>(data: Value, what: &str) -> Result<T, SourceError> {
    serde_json::from_value(data).map_err(|error| {
        SourceError::MarkupChanged(format!("catalog {what} data is invalid: {error}"))
    })
}

impl MetadataCatalog for AniListCatalog {
    async fn detail(&self, kind: MediaKind, id: MediaId) -> Result<MediaDetail, SourceError> {
        let mut detail = self.detail_fast(kind, id).await?;
        detail.episodes = self.episode_titles(&detail).await;
        Ok(detail)
    }

    async fn detail_fast(&self, kind: MediaKind, id: MediaId) -> Result<MediaDetail, SourceError> {
        let variables = json!({ "id": id.get(), "type": media_type(kind) });
        let data = self.graphql.run(&detail_query(), variables).await?;
        let response: RawDetailResponse = parse(data, "detail")?;
        if response.media.summary.is_adult == Some(true) {
            return Err(SourceError::NotFound(id.get().to_string()));
        }
        Ok(map_detail(response.media))
    }

    async fn episode_titles(&self, detail: &MediaDetail) -> Vec<EpisodeInfo> {
        if detail.summary.kind != MediaKind::Anime {
            return detail.episodes.clone();
        }
        titled_episodes(self.http.as_ref(), detail).await
    }

    async fn list(
        &self,
        kind: MediaKind,
        list: MediaListKind,
        page: u32,
    ) -> Result<MediaPage, SourceError> {
        if list == MediaListKind::Seasonal && kind != MediaKind::Anime {
            return Err(SourceError::Unsupported(
                "seasonal lists exist for anime only".into(),
            ));
        }
        let mut variables = json!({
            "page": page,
            "perPage": PAGE_SIZE,
            "type": media_type(kind),
            "sort": sorts(list),
        });
        if kind == MediaKind::Anime {
            variables["country"] = json!(ANIME_COUNTRY);
        }
        if list == MediaListKind::Seasonal {
            let season = season_of(self.clock.now_secs());
            variables["season"] = json!(season.name);
            variables["year"] = json!(season.year);
        }
        let rich = list == MediaListKind::Trending;
        self.page(list_query(rich), variables, page).await
    }

    async fn search(
        &self,
        kind: MediaKind,
        query: &str,
        page: u32,
    ) -> Result<MediaPage, SourceError> {
        let mut variables = json!({
            "page": page,
            "perPage": PAGE_SIZE,
            "type": media_type(kind),
            "search": query.trim(),
        });
        if kind == MediaKind::Anime {
            variables["country"] = json!(ANIME_COUNTRY);
        }
        self.page(search_query(), variables, page).await
    }

    async fn match_titles(
        &self,
        kind: MediaKind,
        titles: &[String],
    ) -> Result<Vec<Vec<MediaSummary>>, SourceError> {
        match_all(&self.graphql, kind, titles).await
    }

    async fn genre_covers(
        &self,
        kind: MediaKind,
        genres: &[String],
    ) -> Result<Vec<Vec<String>>, SourceError> {
        fetch_covers(&self.graphql, kind, genres).await
    }

    async fn profile(&self, kind: ProfileKind, id: u64) -> Result<Profile, SourceError> {
        fetch_profile(&self.graphql, kind, id).await
    }

    async fn search_profiles(
        &self,
        kind: ProfileKind,
        query: &str,
    ) -> Result<Vec<ProfileSummary>, SourceError> {
        fetch_people(&self.graphql, kind, query).await
    }

    async fn discover(
        &self,
        kind: MediaKind,
        filter: &Discover,
        page: u32,
    ) -> Result<MediaPage, SourceError> {
        let country = (kind == MediaKind::Anime).then_some(ANIME_COUNTRY);
        let variables = discover_variables(kind, filter, page, PAGE_SIZE, country);
        self.page(discover_query(), variables, page).await
    }
}
