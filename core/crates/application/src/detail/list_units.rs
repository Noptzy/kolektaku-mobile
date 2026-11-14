use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaRef;
use domain::source::{ItemId, SourceId, SourceLinkStore, Unit};

use crate::sources::{SourceDirectory, SourceHealth, candidate_links};

#[derive(Debug, Clone, PartialEq)]
pub struct UnitsView {
    pub source: SourceId,
    pub item: ItemId,
    pub units: Vec<Unit>,
}

pub struct ListUnits<S: SourceLinkStore> {
    links: Arc<S>,
    directory: Arc<SourceDirectory>,
    health: Arc<SourceHealth>,
}

impl<S: SourceLinkStore> ListUnits<S> {
    pub fn new(links: Arc<S>, directory: Arc<SourceDirectory>, health: Arc<SourceHealth>) -> Self {
        Self {
            links,
            directory,
            health,
        }
    }

    pub async fn execute(
        &self,
        reference: &MediaRef,
        source: Option<&SourceId>,
    ) -> Result<UnitsView, SourceError> {
        let links = candidate_links(
            self.links.as_ref(),
            &self.directory,
            &self.health,
            reference,
        )
        .await;
        let link = links
            .into_iter()
            .find(|link| source.is_none_or(|wanted| link.source == *wanted))
            .ok_or_else(|| SourceError::NotFound("no source has this title".into()))?;
        match self
            .directory
            .get(&link.source)?
            .units(link.item.clone())
            .await
        {
            Ok(units) => {
                self.health.record_success(&link.source);
                Ok(UnitsView {
                    source: link.source,
                    item: link.item,
                    units,
                })
            }
            Err(error) => {
                self.health.record_failure(&link.source, &error);
                Err(error)
            }
        }
    }
}
