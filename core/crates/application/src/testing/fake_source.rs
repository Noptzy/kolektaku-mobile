use std::collections::HashMap;

use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{
    Capabilities, Genre, ItemId, SourceDetail, SourceId, SourceInfo, SourceItem, SourceOrder,
    SourcePage, SourceSearch, StreamSupport, Unit,
};

use super::{CallRecorder, FakeGenres, FakePages, FakeVideo};
use crate::ports::{BoxFuture, PageSource, SourceProvider, VideoSource};

pub struct FakeSource {
    pub(super) info: SourceInfo,
    pub(super) searches: HashMap<String, Vec<SourceItem>>,
    pub(super) latest: Vec<SourceItem>,
    pub(super) details: HashMap<ItemId, SourceDetail>,
    pub(super) units: HashMap<ItemId, Vec<Unit>>,
    pub(super) video: Option<FakeVideo>,
    pub(super) pages: Option<FakePages>,
    pub(super) recorder: CallRecorder,
    pub(super) genres: Option<FakeGenres>,
}

impl FakeSource {
    pub fn new(id: &str, kind: MediaKind) -> Self {
        let info = SourceInfo {
            id: SourceId::new(id),
            name: id.to_string(),
            kind,
            priority: 5,
            capabilities: Capabilities::full(StreamSupport::None),
            summary: String::new(),
        };
        Self {
            info,
            searches: HashMap::new(),
            latest: Vec::new(),
            details: HashMap::new(),
            units: HashMap::new(),
            video: None,
            pages: None,
            recorder: CallRecorder::default(),
            genres: None,
        }
    }

    pub(super) fn enter(&self, call: String) -> Result<(), SourceError> {
        self.recorder.enter(call)
    }
}

pub(super) fn normalize(query: &str) -> String {
    query.trim().to_lowercase()
}

impl SourceProvider for FakeSource {
    fn info(&self) -> &SourceInfo {
        &self.info
    }

    fn latest(&self, page: u32) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            self.enter(format!("latest {page}"))?;
            Ok(SourcePage {
                items: self.latest.clone(),
                page,
                total_pages: 1,
            })
        })
    }

    fn search(&self, search: SourceSearch) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            self.enter(format!("search {}", search.query))?;
            let items = self
                .searches
                .get(&normalize(&search.query))
                .cloned()
                .unwrap_or_default();
            Ok(SourcePage::single(items))
        })
    }

    fn detail(&self, item: ItemId) -> BoxFuture<'_, Result<SourceDetail, SourceError>> {
        Box::pin(async move {
            self.enter(format!("detail {item}"))?;
            self.details
                .get(&item)
                .cloned()
                .ok_or_else(|| SourceError::NotFound(item.to_string()))
        })
    }

    fn units(&self, item: ItemId) -> BoxFuture<'_, Result<Vec<Unit>, SourceError>> {
        Box::pin(async move {
            self.enter(format!("units {item}"))?;
            self.units
                .get(&item)
                .cloned()
                .ok_or_else(|| SourceError::NotFound(item.to_string()))
        })
    }

    fn genres(&self) -> BoxFuture<'_, Result<Vec<Genre>, SourceError>> {
        Box::pin(async move {
            self.enter("genres".into())?;
            self.genres
                .as_ref()
                .map(FakeGenres::list)
                .ok_or_else(|| SourceError::Unsupported("genres".into()))
        })
    }

    fn by_genre(
        &self,
        slug: String,
        page: u32,
        _order: SourceOrder,
    ) -> BoxFuture<'_, Result<SourcePage, SourceError>> {
        Box::pin(async move {
            self.enter(format!("genre {slug} {page}"))?;
            let genres = self
                .genres
                .as_ref()
                .ok_or_else(|| SourceError::Unsupported("genres".into()))?;
            genres.page(&slug, page)
        })
    }

    fn pages(&self) -> Option<&dyn PageSource> {
        self.pages.as_ref().map(|pages| pages as &dyn PageSource)
    }

    fn video(&self) -> Option<&dyn VideoSource> {
        self.video.as_ref().map(|video| video as &dyn VideoSource)
    }
}
