use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaRef;
use domain::source::{ItemId, SourceId, SourceLinkStore, Unit};
use domain::stream::EpisodeServer;

use crate::sources::{SourceDirectory, SourceHealth, candidate_links, find_unit, first_working};

#[derive(Debug, Clone, PartialEq)]
pub struct Playback {
    pub source: SourceId,
    pub item: ItemId,
    pub unit: Unit,
    pub servers: Vec<EpisodeServer>,
    pub switched_from: Option<SourceId>,
}

pub struct OpenEpisode<S: SourceLinkStore> {
    links: Arc<S>,
    directory: Arc<SourceDirectory>,
    health: Arc<SourceHealth>,
}

impl<S: SourceLinkStore> OpenEpisode<S> {
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
        episode: f64,
        preferred: Option<&SourceId>,
        exclude: &[SourceId],
    ) -> Result<Playback, SourceError> {
        let links = candidate_links(
            self.links.as_ref(),
            &self.directory,
            &self.health,
            reference,
        )
        .await;
        let directory = &self.directory;
        let working = first_working(links, &self.health, preferred, exclude, |link| async move {
            let units = directory
                .get(&link.source)?
                .units(link.item.clone())
                .await?;
            let unit = find_unit(&units, episode)
                .cloned()
                .ok_or_else(|| SourceError::NotFound(format!("episode {episode}")))?;
            let servers = directory
                .video(&link.source)?
                .servers(unit.id.clone())
                .await?;
            if servers.is_empty() {
                return Err(SourceError::MarkupChanged("no servers listed".into()));
            }
            Ok((unit, servers))
        })
        .await?;
        let (unit, servers) = working.value;
        Ok(Playback {
            source: working.link.source,
            item: working.link.item,
            unit,
            servers,
            switched_from: working.switched_from,
        })
    }
}
