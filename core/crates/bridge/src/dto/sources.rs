use application::detail::{CatalogView, MediaView, UnitsView};
use application::sources::{ResolvedSources, SourceDirectory};
use domain::source::{Genre, SourceDetail, SourceItem, SourceLink, Unit};

use super::credits::MediaDetailDto;
use super::media::MediaKindDto;
use crate::error::BridgeError;

#[derive(Debug, Clone, PartialEq)]
pub struct SourceLinkDto {
    pub source: String,
    pub source_name: String,
    pub item: String,
    pub confidence: f32,
    pub unit_count: Option<u32>,
    pub manual: bool,
    pub needs_hint: bool,
    pub matched_title: Option<String>,
    pub variants: Vec<String>,
}

pub fn link_dto(link: &SourceLink, directory: &SourceDirectory) -> SourceLinkDto {
    let source_name = directory
        .get(&link.source)
        .map(|source| source.info().name.clone())
        .unwrap_or_else(|_| link.source.to_string());
    SourceLinkDto {
        source: link.source.to_string(),
        source_name,
        item: link.item.to_string(),
        confidence: link.confidence.get(),
        unit_count: link.unit_count,
        manual: link.manual,
        needs_hint: !link.manual && !link.confidence.is_automatic(),
        matched_title: link.title.clone(),
        variants: link
            .variants
            .iter()
            .map(|variant| variant.audio.clone())
            .collect(),
    }
}

pub fn links_dto(resolved: &ResolvedSources, directory: &SourceDirectory) -> Vec<SourceLinkDto> {
    resolved
        .links
        .iter()
        .map(|link| link_dto(link, directory))
        .collect()
}

#[derive(Debug, Clone, PartialEq)]
pub struct UnitDto {
    pub id: String,
    pub number: f64,
    pub label: String,
}

impl From<&Unit> for UnitDto {
    fn from(unit: &Unit) -> Self {
        Self {
            id: unit.id.clone(),
            number: unit.number,
            label: unit.label.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct UnitsDto {
    pub source: String,
    pub item: String,
    pub units: Vec<UnitDto>,
}

impl From<&UnitsView> for UnitsDto {
    fn from(view: &UnitsView) -> Self {
        Self {
            source: view.source.to_string(),
            item: view.item.to_string(),
            units: view.units.iter().map(Into::into).collect(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GenreDto {
    pub slug: String,
    pub name: String,
}

impl From<&Genre> for GenreDto {
    fn from(genre: &Genre) -> Self {
        Self {
            slug: genre.slug.clone(),
            name: genre.name.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceItemDto {
    pub source: String,
    pub item: String,
    pub title: String,
    pub cover_url: Option<String>,
    pub latest_label: Option<String>,
}

pub fn item_dto(source: &str, item: &SourceItem) -> SourceItemDto {
    SourceItemDto {
        source: source.to_string(),
        item: item.item_id.to_string(),
        title: item.title.clone(),
        cover_url: item.cover_url.clone(),
        latest_label: item.latest_label.clone(),
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceStatusDto {
    pub id: String,
    pub name: String,
    pub kind: MediaKindDto,
    pub enabled: bool,
    pub skipped: bool,
    pub summary: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PingVerdictDto {
    Online,
    Changed,
    Offline,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourcePingDto {
    pub id: String,
    pub verdict: PingVerdictDto,
    pub millis: u32,
}

#[derive(Debug, Clone, PartialEq)]
pub struct SiteDetailDto {
    pub source: String,
    pub item: String,
    pub title: String,
    pub cover_url: Option<String>,
    pub alternative_titles: Vec<String>,
    pub type_text: Option<String>,
    pub year: Option<u16>,
    pub unit_count: Option<u32>,
    pub origin: Option<String>,
    pub synopsis: String,
    pub genres: Vec<String>,
    pub latest_label: Option<String>,
}

fn site_dto(source: &str, detail: &SourceDetail) -> SiteDetailDto {
    SiteDetailDto {
        source: source.to_string(),
        item: detail.item.item_id.to_string(),
        title: detail.item.title.clone(),
        cover_url: detail.item.cover_url.clone(),
        alternative_titles: detail.alternative_titles.clone(),
        type_text: detail.type_text.clone(),
        year: detail.year,
        unit_count: detail.unit_count,
        origin: detail.origin.clone(),
        synopsis: detail.synopsis.clone(),
        genres: detail.genres.clone(),
        latest_label: detail.item.latest_label.clone(),
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct CatalogDetailDto {
    pub detail: MediaDetailDto,
    pub sources: Vec<SourceLinkDto>,
    pub resolve_error: Option<BridgeError>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct DetailViewDto {
    pub catalog: Option<CatalogDetailDto>,
    pub site: Option<SiteDetailDto>,
}

fn catalog_view_dto(view: &CatalogView, directory: &SourceDirectory) -> CatalogDetailDto {
    CatalogDetailDto {
        detail: (&view.detail).into(),
        sources: links_dto(&view.sources, directory),
        resolve_error: view.resolve_error.clone().map(Into::into),
    }
}

pub fn view_dto(view: &MediaView, directory: &SourceDirectory) -> DetailViewDto {
    match view {
        MediaView::Catalog(catalog) => DetailViewDto {
            catalog: Some(catalog_view_dto(catalog, directory)),
            site: None,
        },
        MediaView::Site(site) => DetailViewDto {
            catalog: None,
            site: Some(site_dto(site.source.as_str(), &site.detail)),
        },
    }
}
