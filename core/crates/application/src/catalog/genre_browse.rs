use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{Genre, SourceOrder, SourcePage};
use tokio::task::JoinSet;

use super::compose::SiteItems;
use super::site_feed::cards_for_sites;
use super::{MediaCard, SearchNotice};
use crate::ports::{Clock, MetadataCatalog, SourceProvider};

#[derive(Debug, Clone, PartialEq)]
pub struct GenrePage {
    pub cards: Vec<MediaCard>,
    pub has_next_page: bool,
    pub notices: Vec<SearchNotice>,
}

pub struct GenreBrowse<C: MetadataCatalog> {
    catalog: Arc<C>,
    sources: Vec<Arc<dyn SourceProvider>>,
    clock: Arc<dyn Clock>,
}

fn is_missing_feature(error: &SourceError) -> bool {
    matches!(
        error,
        SourceError::Unsupported(_) | SourceError::NotFound(_)
    )
}

impl<C: MetadataCatalog + 'static> GenreBrowse<C> {
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

    pub async fn genres(&self) -> Result<Vec<Genre>, SourceError> {
        let mut tasks = JoinSet::new();
        for (index, source) in self.sources.iter().enumerate() {
            let source = Arc::clone(source);
            tasks.spawn(async move { (index, source.genres().await) });
        }
        let mut answers: Vec<(usize, Result<Vec<Genre>, SourceError>)> = Vec::new();
        while let Some(Ok(answer)) = tasks.join_next().await {
            answers.push(answer);
        }
        answers.sort_by_key(|(index, _)| *index);
        let mut merged: Vec<Genre> = Vec::new();
        let mut first_error = None;
        for (_, answer) in answers {
            match answer {
                Ok(list) => {
                    for genre in list {
                        if !merged.iter().any(|known| known.slug == genre.slug) {
                            merged.push(genre);
                        }
                    }
                }
                Err(error) if is_missing_feature(&error) => {}
                Err(error) => first_error = first_error.or(Some(error)),
            }
        }
        match (merged.is_empty(), first_error) {
            (true, Some(error)) => Err(error),
            _ => Ok(merged),
        }
    }

    pub async fn by_genre(
        &self,
        kind: MediaKind,
        slug: &str,
        page: u32,
        order: SourceOrder,
    ) -> Result<GenrePage, SourceError> {
        let mut tasks = JoinSet::new();
        for (index, source) in self.sources.iter().enumerate() {
            let source = Arc::clone(source);
            let slug = slug.to_string();
            tasks.spawn(async move { (index, source.by_genre(slug, page, order).await) });
        }
        let mut answers: Vec<(usize, Result<SourcePage, SourceError>)> = Vec::new();
        while let Some(Ok(answer)) = tasks.join_next().await {
            answers.push(answer);
        }
        answers.sort_by_key(|(index, _)| *index);
        let mut sites = Vec::new();
        let mut notices = Vec::new();
        let mut has_next_page = false;
        let mut first_error = None;
        for (index, answer) in answers {
            let source = self.sources[index].info().id.clone();
            match answer {
                Ok(listing) => {
                    has_next_page |= listing.page < listing.total_pages;
                    sites.push(SiteItems {
                        source,
                        items: listing.items,
                    });
                }
                Err(error) if is_missing_feature(&error) => {}
                Err(error) => {
                    first_error = first_error.or(Some(error.clone()));
                    notices.push(SearchNotice {
                        origin: Some(source),
                        error,
                    });
                }
            }
        }
        if sites.is_empty()
            && let Some(error) = first_error
        {
            return Err(error);
        }
        let (cards, failure) =
            cards_for_sites(self.catalog.as_ref(), kind, sites, self.clock.now_secs()).await;
        notices.extend(failure.map(|error| SearchNotice {
            origin: None,
            error,
        }));
        Ok(GenrePage {
            cards,
            has_next_page,
            notices,
        })
    }
}
