use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaKind, MediaPage};

use super::compose::{SiteItems, compose_cards};
use super::replies::{Ask, Replies, ask_participants};
use super::{SearchNotice, SearchOutcome};
use crate::matching::relaxed_queries;
use crate::ports::{Clock, MetadataCatalog, SourceProvider};

const MAX_EXTRA_REQUESTS: usize = 2;

pub struct SearchMedia<C: MetadataCatalog> {
    catalog: Arc<C>,
    sources: Vec<Arc<dyn SourceProvider>>,
    clock: Arc<dyn Clock>,
}

impl<C: MetadataCatalog + 'static> SearchMedia<C> {
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

    pub async fn execute(
        &self,
        kind: MediaKind,
        query: &str,
        page: u32,
    ) -> Result<SearchOutcome, SourceError> {
        let everyone = Ask::everyone(self.sources.len());
        let mut replies = self.ask(kind, query, page, &everyone).await;
        if !replies.has_results() && replies.succeeded_anywhere() {
            self.retry_relaxed(&mut replies, kind, query, page).await;
        }
        self.outcome(replies)
    }

    async fn ask(&self, kind: MediaKind, query: &str, page: u32, ask: &Ask) -> Replies {
        ask_participants(&self.catalog, &self.sources, kind, query, page, ask).await
    }

    async fn retry_relaxed(&self, replies: &mut Replies, kind: MediaKind, query: &str, page: u32) {
        for relaxed in relaxed_queries(query).into_iter().take(MAX_EXTRA_REQUESTS) {
            let ask = replies.empty_participants();
            if ask.nobody() {
                return;
            }
            let extra = self.ask(kind, &relaxed, page, &ask).await;
            replies.absorb(extra, query);
            if replies.has_results() {
                return;
            }
        }
    }

    fn outcome(&self, replies: Replies) -> Result<SearchOutcome, SourceError> {
        let errors = replies.errors();
        if !replies.succeeded_anywhere() {
            let first = errors.into_iter().next().map(|(_, error)| error);
            return Err(
                first.unwrap_or_else(|| SourceError::Unavailable("nothing answered".into()))
            );
        }
        let notices = errors
            .into_iter()
            .map(|(origin, error)| SearchNotice {
                origin: origin.map(|index| self.sources[index].info().id.clone()),
                error,
            })
            .collect();
        let media = match replies.media {
            Some(Ok(page)) => page,
            _ => MediaPage::empty(1),
        };
        let mut has_next_page = media.has_next_page;
        let mut sites = Vec::new();
        for (index, reply) in replies.items.into_iter().enumerate() {
            if let Some(Ok(page)) = reply {
                has_next_page |= page.page < page.total_pages;
                sites.push(SiteItems {
                    source: self.sources[index].info().id.clone(),
                    items: page.items,
                });
            }
        }
        Ok(SearchOutcome {
            cards: compose_cards(media.items, &sites, self.clock.now_secs()),
            has_next_page,
            notices,
        })
    }
}
