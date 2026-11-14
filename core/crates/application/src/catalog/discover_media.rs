use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{Discover, MediaKind};

use super::SearchOutcome;
use super::compose::compose_cards;
use crate::ports::{Clock, MetadataCatalog};

pub struct DiscoverMedia<C: MetadataCatalog> {
    catalog: Arc<C>,
    clock: Arc<dyn Clock>,
}

impl<C: MetadataCatalog> DiscoverMedia<C> {
    pub fn new(catalog: Arc<C>, clock: Arc<dyn Clock>) -> Self {
        Self { catalog, clock }
    }

    pub async fn execute(
        &self,
        kind: MediaKind,
        filter: &Discover,
        page: u32,
    ) -> Result<SearchOutcome, SourceError> {
        let media = self.catalog.discover(kind, filter, page).await?;
        Ok(SearchOutcome {
            cards: compose_cards(media.items, &[], self.clock.now_secs()),
            has_next_page: media.has_next_page,
            notices: Vec::new(),
        })
    }
}
