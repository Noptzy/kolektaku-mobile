use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaFormat, MediaId, MediaKind, MediaRef};
use domain::scene::SceneMatch;
use domain::source::SourceLinkStore;

use crate::detail::{MediaView, MediaViewer};
use crate::ports::MetadataCatalog;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DetailReason {
    NotAvailable,
    NoEpisode,
}

#[derive(Debug, Clone, PartialEq)]
pub enum SceneTarget {
    Watch {
        media: MediaId,
        episode: f64,
        start_secs: f64,
        duration_secs: Option<f64>,
    },
    Detail {
        media: MediaId,
        reason: DetailReason,
    },
}

pub struct OpenScene<C: MetadataCatalog, S: SourceLinkStore> {
    viewer: Arc<MediaViewer<C, S>>,
}

impl<C: MetadataCatalog + 'static, S: SourceLinkStore + 'static> OpenScene<C, S> {
    pub fn new(viewer: Arc<MediaViewer<C, S>>) -> Self {
        Self { viewer }
    }

    pub async fn execute(&self, scene: &SceneMatch) -> Result<SceneTarget, SourceError> {
        let media = scene.media_id;
        let reference = MediaRef::catalog(media);
        let view = self.viewer.execute(MediaKind::Anime, &reference).await?;
        let MediaView::Catalog(catalog) = view else {
            return Ok(detail(media, DetailReason::NotAvailable));
        };
        if catalog.sources.links.is_empty() {
            return match catalog.resolve_error {
                Some(error) => Err(error),
                None => Ok(detail(media, DetailReason::NotAvailable)),
            };
        }
        let is_film = catalog.detail.summary.format == Some(MediaFormat::Movie);
        let episode = scene.episode.or(is_film.then_some(1.0));
        Ok(match episode {
            Some(episode) => SceneTarget::Watch {
                media,
                episode,
                start_secs: scene.start_secs(),
                duration_secs: scene.duration_secs,
            },
            None => detail(media, DetailReason::NoEpisode),
        })
    }
}

fn detail(media: MediaId, reason: DetailReason) -> SceneTarget {
    SceneTarget::Detail { media, reason }
}
