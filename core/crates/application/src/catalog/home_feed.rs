use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaKind, MediaListKind, MediaPage};
use domain::source::{SourceId, SourcePage};
use tokio::task::JoinSet;

use super::compose::SiteItems;
use super::site_feed::cards_for_sites;
use super::{MediaCard, SearchNotice};
use crate::ports::{Clock, MetadataCatalog, SourceProvider};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HomeSectionId {
    Trending,
    Seasonal,
    Popular,
    Latest,
}

#[derive(Debug, Clone, PartialEq)]
pub struct HomeSection {
    pub id: HomeSectionId,
    pub cards: Vec<MediaCard>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct HomeOutcome {
    pub sections: Vec<HomeSection>,
    pub notices: Vec<SearchNotice>,
}

enum Part {
    List(MediaListKind, Result<MediaPage, SourceError>),
    Latest(usize, Result<SourcePage, SourceError>),
}

pub struct HomeFeed<C: MetadataCatalog> {
    catalog: Arc<C>,
    sources: Vec<Arc<dyn SourceProvider>>,
    clock: Arc<dyn Clock>,
}

fn lists_for(kind: MediaKind) -> Vec<MediaListKind> {
    match kind {
        MediaKind::Anime => vec![
            MediaListKind::Trending,
            MediaListKind::Seasonal,
            MediaListKind::Popular,
        ],
        MediaKind::Manga => vec![MediaListKind::Trending, MediaListKind::Popular],
    }
}

fn section_of(list: MediaListKind) -> HomeSectionId {
    match list {
        MediaListKind::Trending => HomeSectionId::Trending,
        MediaListKind::Seasonal => HomeSectionId::Seasonal,
        MediaListKind::Popular => HomeSectionId::Popular,
    }
}

fn record(
    notices: &mut Vec<SearchNotice>,
    first_error: &mut Option<SourceError>,
    origin: Option<SourceId>,
    error: SourceError,
) {
    *first_error = first_error.take().or(Some(error.clone()));
    notices.push(SearchNotice { origin, error });
}

impl<C: MetadataCatalog + 'static> HomeFeed<C> {
    pub fn new(
        catalog: Arc<C>,
        sources: Vec<Arc<dyn SourceProvider>>,
        clock: Arc<dyn Clock>,
    ) -> Self {
        Self {
            catalog,
            sources,
            clock,
        }
    }

    pub async fn execute(&self, kind: MediaKind) -> Result<HomeOutcome, SourceError> {
        let mut sections = Vec::new();
        let mut notices = Vec::new();
        let mut sites = Vec::new();
        let mut answered = false;
        let mut first_error = None;
        for part in self.fetch_parts(kind).await {
            match part {
                Part::List(list, Ok(page)) => {
                    answered = true;
                    let cards = page.items.into_iter().map(MediaCard::of_media).collect();
                    sections.push(HomeSection {
                        id: section_of(list),
                        cards,
                    });
                }
                Part::List(_, Err(error)) => record(&mut notices, &mut first_error, None, error),
                Part::Latest(index, Ok(page)) => {
                    answered = true;
                    let source = self.sources[index].info().id.clone();
                    sites.push(SiteItems {
                        source,
                        items: page.items,
                    });
                }
                Part::Latest(index, Err(error)) => {
                    let origin = Some(self.sources[index].info().id.clone());
                    record(&mut notices, &mut first_error, origin, error);
                }
            }
        }
        if !answered {
            let error =
                first_error.unwrap_or_else(|| SourceError::Unavailable("nothing answered".into()));
            return Err(error);
        }
        sections.sort_by_key(|section| section.id as u8);
        if !sites.is_empty() {
            let cards = self.latest_cards(kind, sites, &mut notices).await;
            sections.push(HomeSection {
                id: HomeSectionId::Latest,
                cards,
            });
        }
        Ok(HomeOutcome { sections, notices })
    }

    async fn fetch_parts(&self, kind: MediaKind) -> Vec<Part> {
        let mut tasks = JoinSet::new();
        for list in lists_for(kind) {
            let catalog = Arc::clone(&self.catalog);
            tasks.spawn(async move { Part::List(list, catalog.list(kind, list, 1).await) });
        }
        for (index, source) in self.sources.iter().enumerate() {
            let source = Arc::clone(source);
            tasks.spawn(async move { Part::Latest(index, source.latest(1).await) });
        }
        let mut parts = Vec::new();
        while let Some(Ok(part)) = tasks.join_next().await {
            parts.push(part);
        }
        parts
    }

    async fn latest_cards(
        &self,
        kind: MediaKind,
        mut sites: Vec<SiteItems>,
        notices: &mut Vec<SearchNotice>,
    ) -> Vec<MediaCard> {
        sites.sort_by_key(|site| self.priority_of(&site.source));
        let now = self.clock.now_secs();
        let (cards, failure) = cards_for_sites(self.catalog.as_ref(), kind, sites, now).await;
        notices.extend(failure.map(|error| SearchNotice {
            origin: None,
            error,
        }));
        cards
    }

    fn priority_of(&self, source: &SourceId) -> u8 {
        self.sources
            .iter()
            .find(|known| known.info().id == *source)
            .map_or(u8::MAX, |known| known.info().priority)
    }
}
