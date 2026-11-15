use std::sync::Arc;

use domain::library::LibraryRepository;
use domain::media::{MediaFormat, MediaId, MediaKind, MediaRef};

use crate::ports::MetadataCatalog;

pub const MIGRATION_FLAG: &str = "migration.novel-entries";
const DONE: &str = "done";
const LOOKUP_CHUNK: usize = 50;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum NovelMigration {
    AlreadyDone,
    Moved(usize),
    Postponed(String),
}

pub struct MigrateNovelEntries<L: LibraryRepository, C: MetadataCatalog> {
    library: Arc<L>,
    catalog: Arc<C>,
}

impl<L: LibraryRepository, C: MetadataCatalog> MigrateNovelEntries<L, C> {
    pub fn new(library: Arc<L>, catalog: Arc<C>) -> Self {
        Self { library, catalog }
    }

    pub async fn execute(&self) -> NovelMigration {
        match self.library.preference(MIGRATION_FLAG).await {
            Ok(Some(flag)) if flag == DONE => return NovelMigration::AlreadyDone,
            Ok(_) => {}
            Err(error) => return NovelMigration::Postponed(error.to_string()),
        }
        match self.run().await {
            Ok(moved) => {
                let _ = self.library.set_preference(MIGRATION_FLAG, DONE).await;
                NovelMigration::Moved(moved)
            }
            Err(reason) => NovelMigration::Postponed(reason),
        }
    }

    async fn run(&self) -> Result<usize, String> {
        let ids = self.comic_ids().await?;
        if ids.is_empty() {
            return Ok(0);
        }
        let mut novels: Vec<MediaRef> = Vec::new();
        for chunk in ids.chunks(LOOKUP_CHUNK) {
            let formats = self
                .catalog
                .comic_formats(chunk)
                .await
                .map_err(|error| error.to_string())?;
            novels.extend(
                formats
                    .into_iter()
                    .filter(|(_, format)| *format == Some(MediaFormat::Novel))
                    .map(|(id, _)| MediaRef::catalog(id)),
            );
        }
        self.library
            .move_entries(MediaKind::Manga, MediaKind::Novel, &novels)
            .await
            .map_err(|error| error.to_string())
    }

    async fn comic_ids(&self) -> Result<Vec<MediaId>, String> {
        let favorites = self
            .library
            .favorites(MediaKind::Manga)
            .await
            .map_err(|error| error.to_string())?;
        let history = self
            .library
            .history(MediaKind::Manga)
            .await
            .map_err(|error| error.to_string())?;
        let mut ids: Vec<MediaId> = Vec::new();
        let references = favorites
            .iter()
            .map(|item| &item.entry.media)
            .chain(history.iter().map(|item| &item.entry.media));
        for id in references.filter_map(MediaRef::catalog_id) {
            if !ids.contains(&id) {
                ids.push(id);
            }
        }
        Ok(ids)
    }
}
