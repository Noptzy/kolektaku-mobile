use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaRef;
use domain::source::{ChapterPages, ItemId, SourceId, SourceLinkStore, Unit};

use crate::sources::{SourceDirectory, SourceHealth, candidate_links, find_unit, first_working};

#[derive(Debug, Clone, PartialEq)]
pub struct ChapterView {
    pub source: SourceId,
    pub item: ItemId,
    pub unit: Unit,
    pub pages: ChapterPages,
    pub switched_from: Option<SourceId>,
}

pub struct OpenChapter<S: SourceLinkStore> {
    links: Arc<S>,
    directory: Arc<SourceDirectory>,
    health: Arc<SourceHealth>,
}

impl<S: SourceLinkStore> OpenChapter<S> {
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
        chapter: f64,
        preferred: Option<&SourceId>,
        exclude: &[SourceId],
    ) -> Result<ChapterView, SourceError> {
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
            let unit = find_unit(&units, chapter)
                .cloned()
                .ok_or_else(|| SourceError::NotFound(format!("chapter {chapter}")))?;
            let pages = directory
                .pages(&link.source)?
                .chapter_pages(unit.id.clone())
                .await?;
            Ok((unit, pages))
        })
        .await?;
        let (unit, pages) = working.value;
        Ok(ChapterView {
            source: working.link.source,
            item: working.link.item,
            unit,
            pages,
            switched_from: working.switched_from,
        })
    }
}
