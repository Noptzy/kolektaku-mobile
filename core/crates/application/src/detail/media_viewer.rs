use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaDetail, MediaKind, MediaRef};
use domain::source::{SourceDetail, SourceId, SourceLinkStore};

use crate::ports::MetadataCatalog;
use crate::sources::{ResolveSources, ResolvedSources, SourceDirectory};

#[derive(Debug, Clone, PartialEq)]
pub struct CatalogView {
    pub detail: MediaDetail,
    pub sources: ResolvedSources,
    pub resolve_error: Option<SourceError>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SiteView {
    pub source: SourceId,
    pub detail: SourceDetail,
}

#[derive(Debug, Clone, PartialEq)]
pub enum MediaView {
    Catalog(Box<CatalogView>),
    Site(Box<SiteView>),
}

pub struct MediaViewer<C: MetadataCatalog, S: SourceLinkStore> {
    catalog: Arc<C>,
    resolver: Arc<ResolveSources<S>>,
    directory: Arc<SourceDirectory>,
}

impl<C: MetadataCatalog + 'static, S: SourceLinkStore + 'static> MediaViewer<C, S> {
    pub fn new(
        catalog: Arc<C>,
        resolver: Arc<ResolveSources<S>>,
        directory: Arc<SourceDirectory>,
    ) -> Self {
        Self {
            catalog,
            resolver,
            directory,
        }
    }

    pub async fn execute(
        &self,
        kind: MediaKind,
        reference: &MediaRef,
    ) -> Result<MediaView, SourceError> {
        match reference {
            MediaRef::Catalog { id } => {
                let mut detail = self.catalog.detail_fast(kind, *id).await?;
                let (resolved, titled) = tokio::join!(
                    self.resolver.execute(&detail.summary),
                    self.catalog.episode_titles(&detail)
                );
                detail.episodes = titled;
                let (sources, resolve_error) = match resolved {
                    Ok(resolved) => (resolved, None),
                    Err(error) => (ResolvedSources { links: Vec::new() }, Some(error)),
                };
                Ok(MediaView::Catalog(Box::new(CatalogView {
                    detail,
                    sources,
                    resolve_error,
                })))
            }
            MediaRef::Source { source, item } => {
                let detail = self.directory.get(source)?.detail(item.clone()).await?;
                Ok(MediaView::Site(Box::new(SiteView {
                    source: source.clone(),
                    detail,
                })))
            }
        }
    }
}
