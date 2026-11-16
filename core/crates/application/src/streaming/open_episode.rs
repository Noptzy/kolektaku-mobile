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
    pub audio: Option<String>,
    pub audio_options: Vec<String>,
}

struct Opened {
    unit: Unit,
    servers: Vec<EpisodeServer>,
    item: ItemId,
    audio: Option<String>,
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
        self.execute_audio(reference, episode, preferred, exclude, None)
            .await
    }

    pub async fn execute_audio(
        &self,
        reference: &MediaRef,
        episode: f64,
        preferred: Option<&SourceId>,
        exclude: &[SourceId],
        audio: Option<&str>,
    ) -> Result<Playback, SourceError> {
        let wanted = audio.map(str::to_string);
        let links = candidate_links(
            self.links.as_ref(),
            &self.directory,
            &self.health,
            reference,
        )
        .await;
        let directory = &self.directory;
        let working = first_working(links, &self.health, preferred, exclude, |link| {
            let wanted = wanted.clone();
            async move {
                let variant = wanted.as_deref().and_then(|label| link.variant_for(label));
                let item = variant.map_or_else(|| link.item.clone(), |found| found.item.clone());
                let units = directory.get(&link.source)?.units(item.clone()).await?;
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
                let audio = variant.map(|found| found.audio.clone());
                Ok(Opened {
                    unit,
                    servers,
                    item,
                    audio,
                })
            }
        })
        .await?;
        let opened = working.value;
        let audio_options = working
            .link
            .variants
            .iter()
            .map(|variant| variant.audio.clone())
            .collect();
        Ok(Playback {
            source: working.link.source,
            item: opened.item,
            unit: opened.unit,
            servers: opened.servers,
            switched_from: working.switched_from,
            audio: opened.audio,
            audio_options,
        })
    }
}
