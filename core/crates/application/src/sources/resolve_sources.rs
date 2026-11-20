use std::collections::HashMap;
use std::sync::Arc;

use domain::error::{SourceError, StorageError};
use domain::media::{MediaRef, MediaSummary};
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore};

use super::SourceHealth;
use super::merge::{is_fresh, merge_answers};
use super::rank::rank_links;
use super::resolve_search::{search_sources, unlinked_sources};
use super::resolved_sources::ResolvedSources;
use crate::ports::{Clock, SourceProvider};
use crate::settings::AppSettingsStore;

pub struct ResolveSources<S: SourceLinkStore> {
    sources: Vec<Arc<dyn SourceProvider>>,
    store: Arc<S>,
    health: Arc<SourceHealth>,
    clock: Arc<dyn Clock>,
    settings: Option<Arc<AppSettingsStore>>,
}

impl<S: SourceLinkStore + 'static> ResolveSources<S> {
    pub fn new(
        sources: Vec<Arc<dyn SourceProvider>>,
        store: Arc<S>,
        health: Arc<SourceHealth>,
        clock: Arc<dyn Clock>,
    ) -> Self {
        Self {
            sources,
            store,
            health,
            clock,
            settings: None,
        }
    }

    pub fn with_settings(mut self, settings: Arc<AppSettingsStore>) -> Self {
        self.settings = Some(settings);
        self
    }

    pub async fn execute(&self, media: &MediaSummary) -> Result<ResolvedSources, SourceError> {
        let reference = MediaRef::catalog(media.id);
        let stored = self.store.links_for(&reference).await.unwrap_or_default();
        let (active, inactive): (Vec<SourceLink>, Vec<SourceLink>) = stored
            .into_iter()
            .partition(|link| self.is_active(&link.source));
        let now = self.clock.now_secs();
        if !active.is_empty()
            && active.iter().all(|link| is_fresh(link, now))
            && unlinked_sources(&self.sources, &self.health, &reference, &active, now).is_empty()
        {
            return Ok(self.ranked(active));
        }
        let answers = search_sources(&self.sources, &self.health, media, &active, now).await;
        let merged = merge_answers(&active, answers);
        if merged.links.is_empty() {
            return self.without_new_links(active, merged.answered, merged.first_error);
        }
        let mut persisted = merged.links.clone();
        persisted.extend(inactive);
        let _ = self.store.save_all(&reference, persisted).await;
        Ok(self.ranked(merged.links))
    }

    pub async fn choose(
        &self,
        reference: &MediaRef,
        source: SourceId,
        item: ItemId,
    ) -> Result<ResolvedSources, StorageError> {
        let stored = self.store.links_for(reference).await?;
        let previous = stored
            .iter()
            .find(|link| link.source == source && link.item == item)
            .cloned();
        let mut links: Vec<SourceLink> = stored
            .into_iter()
            .filter(|link| link.source != source)
            .collect();
        let mut chosen = SourceLink::chosen_by_user(source, item, self.clock.now_secs());
        if let Some(known) = previous {
            chosen.variants = known.variants;
            chosen.title = known.title;
            chosen.unit_count = known.unit_count;
        }
        links.push(chosen);
        self.store.save_all(reference, links.clone()).await?;
        Ok(self.ranked(
            links
                .into_iter()
                .filter(|link| self.is_active(&link.source))
                .collect(),
        ))
    }

    pub async fn forget(&self, reference: &MediaRef) -> Result<(), StorageError> {
        self.store.remove(reference).await
    }

    fn is_active(&self, source: &SourceId) -> bool {
        self.sources.iter().any(|known| known.info().id == *source)
    }

    fn ranked(&self, links: Vec<SourceLink>) -> ResolvedSources {
        let priorities: HashMap<SourceId, u8> = self
            .sources
            .iter()
            .map(|source| (source.info().id.clone(), source.info().priority))
            .collect();
        let preferred = self
            .settings
            .as_ref()
            .and_then(|settings| settings.preferred_anime_source());
        ResolvedSources {
            links: rank_links(links, &priorities, &self.health, preferred.as_ref()),
        }
    }

    fn without_new_links(
        &self,
        stored: Vec<SourceLink>,
        answered: bool,
        first_error: Option<SourceError>,
    ) -> Result<ResolvedSources, SourceError> {
        if !stored.is_empty() {
            return Ok(self.ranked(stored));
        }
        match (answered, first_error) {
            (false, Some(error)) => Err(error),
            _ => Ok(ResolvedSources { links: Vec::new() }),
        }
    }
}
