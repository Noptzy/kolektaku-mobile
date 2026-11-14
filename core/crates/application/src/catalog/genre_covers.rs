use std::collections::HashSet;
use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaKind;

use crate::ports::MetadataCatalog;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GenreCover {
    pub genre: String,
    pub cover_url: String,
}

pub struct GenreCovers<C: MetadataCatalog> {
    catalog: Arc<C>,
}

impl<C: MetadataCatalog> GenreCovers<C> {
    pub fn new(catalog: Arc<C>) -> Self {
        Self { catalog }
    }

    pub async fn execute(
        &self,
        kind: MediaKind,
        genres: &[String],
    ) -> Result<Vec<GenreCover>, SourceError> {
        if genres.is_empty() {
            return Ok(Vec::new());
        }
        let candidates = self.catalog.genre_covers(kind, genres).await?;
        Ok(assign_covers(genres, &candidates))
    }
}

pub fn assign_covers(genres: &[String], candidates: &[Vec<String>]) -> Vec<GenreCover> {
    let mut used: HashSet<&str> = HashSet::new();
    genres
        .iter()
        .enumerate()
        .filter_map(|(index, genre)| {
            let list = candidates.get(index)?;
            let url = list
                .iter()
                .find(|url| !used.contains(url.as_str()))
                .or_else(|| list.first())?;
            used.insert(url.as_str());
            Some(GenreCover {
                genre: genre.clone(),
                cover_url: url.clone(),
            })
        })
        .collect()
}
