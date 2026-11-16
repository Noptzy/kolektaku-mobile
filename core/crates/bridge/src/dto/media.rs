use domain::media::{MediaId, MediaKind, MediaRef, MediaSummary};
use domain::source::{ItemId, SourceId};
use serde::Serialize;

pub fn tag<T: Serialize>(value: &T) -> String {
    serde_json::to_value(value)
        .ok()
        .and_then(|json| json.as_str().map(str::to_string))
        .unwrap_or_default()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MediaKindDto {
    Anime,
    Manga,
    Novel,
}

impl From<MediaKindDto> for MediaKind {
    fn from(kind: MediaKindDto) -> Self {
        match kind {
            MediaKindDto::Anime => Self::Anime,
            MediaKindDto::Manga => Self::Manga,
            MediaKindDto::Novel => Self::Novel,
        }
    }
}

impl From<MediaKind> for MediaKindDto {
    fn from(kind: MediaKind) -> Self {
        match kind {
            MediaKind::Anime => Self::Anime,
            MediaKind::Manga => Self::Manga,
            MediaKind::Novel => Self::Novel,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MediaRefKind {
    Catalog,
    Source,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct MediaRefDto {
    pub kind: MediaRefKind,
    pub id: u64,
    pub source: String,
    pub item: String,
}

impl MediaRefDto {
    pub fn catalog(id: u64) -> Self {
        Self {
            kind: MediaRefKind::Catalog,
            id,
            source: String::new(),
            item: String::new(),
        }
    }

    pub fn site(source: impl Into<String>, item: impl Into<String>) -> Self {
        Self {
            kind: MediaRefKind::Source,
            id: 0,
            source: source.into(),
            item: item.into(),
        }
    }

    pub fn to_domain(&self) -> Option<MediaRef> {
        match self.kind {
            MediaRefKind::Catalog => MediaId::new(self.id).map(MediaRef::catalog),
            MediaRefKind::Source if self.source.is_empty() || self.item.is_empty() => None,
            MediaRefKind::Source => Some(MediaRef::source(
                SourceId::new(self.source.clone()),
                ItemId::new(self.item.clone()),
            )),
        }
    }

    pub fn require(&self) -> Result<MediaRef, crate::error::BridgeError> {
        self.to_domain()
            .ok_or_else(|| crate::error::BridgeError::not_found("invalid reference"))
    }
}

impl From<&MediaRef> for MediaRefDto {
    fn from(reference: &MediaRef) -> Self {
        match reference {
            MediaRef::Catalog { id } => Self::catalog(id.get()),
            MediaRef::Source { source, item } => Self::site(source.as_str(), item.as_str()),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct MediaSummaryDto {
    pub id: u64,
    pub kind: MediaKindDto,
    pub title_romaji: String,
    pub title_english: Option<String>,
    pub title_native: Option<String>,
    pub synonyms: Vec<String>,
    pub cover_url: Option<String>,
    pub format: Option<String>,
    pub status: Option<String>,
    pub year: Option<u16>,
    pub unit_count: Option<u32>,
    pub score: Option<f32>,
    pub genres: Vec<String>,
    pub country_of_origin: Option<String>,
}

impl From<&MediaSummary> for MediaSummaryDto {
    fn from(media: &MediaSummary) -> Self {
        Self {
            id: media.id.get(),
            kind: media.kind.into(),
            title_romaji: media.title.romaji.clone(),
            title_english: media.title.english.clone(),
            title_native: media.title.native.clone(),
            synonyms: media.synonyms.clone(),
            cover_url: media.cover_url.clone(),
            format: media.format.as_ref().map(tag),
            status: media.status.as_ref().map(tag),
            year: media.year,
            unit_count: media.unit_count,
            score: media.score,
            genres: media.genres.clone(),
            country_of_origin: media.country_of_origin.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{MediaFormat, MediaStatus, MediaTitle};

    use super::*;

    #[test]
    fn enums_are_sent_as_their_catalog_names() {
        let mut media = MediaSummary::new(
            MediaId::new(21519).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Kimi no Na wa."),
        );
        media.format = Some(MediaFormat::TvShort);
        media.status = Some(MediaStatus::NotYetReleased);
        let dto = MediaSummaryDto::from(&media);
        assert_eq!(dto.format.as_deref(), Some("TV_SHORT"));
        assert_eq!(dto.status.as_deref(), Some("NOT_YET_RELEASED"));
        assert_eq!(dto.kind, MediaKindDto::Anime);
    }

    #[test]
    fn references_round_trip_and_a_zero_id_is_rejected() {
        let catalog = MediaRef::catalog(MediaId::new(5).unwrap());
        assert_eq!(MediaRefDto::from(&catalog).to_domain(), Some(catalog));
        let site = MediaRef::source(SourceId::new("komiku"), ItemId::new("berserk"));
        assert_eq!(MediaRefDto::from(&site).to_domain(), Some(site));
        assert_eq!(MediaRefDto::catalog(0).to_domain(), None);
        assert_eq!(MediaRefDto::site("", "x").to_domain(), None);
        assert!(MediaRefDto::catalog(0).require().is_err());
    }

    #[test]
    fn kinds_convert_both_ways() {
        for kind in [MediaKind::Anime, MediaKind::Manga, MediaKind::Novel] {
            assert_eq!(MediaKind::from(MediaKindDto::from(kind)), kind);
        }
    }
}
