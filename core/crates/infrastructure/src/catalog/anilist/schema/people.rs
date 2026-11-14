use serde::Deserialize;

use super::summary::{RawImage, RawSummary, RawTitle};

#[derive(Debug, Deserialize)]
pub struct RawPeopleResponse {
    #[serde(rename = "Page")]
    pub page: RawPeoplePage,
}

#[derive(Debug, Deserialize)]
pub struct RawPeoplePage {
    pub characters: Option<Vec<RawPerson>>,
    pub staff: Option<Vec<RawPerson>>,
    pub studios: Option<Vec<RawPerson>>,
}

#[derive(Debug, Deserialize)]
#[serde(untagged)]
pub enum RawPersonName {
    Plain(String),
    Full {
        full: Option<String>,
        native: Option<String>,
    },
}

#[derive(Debug, Deserialize)]
pub struct RawPerson {
    pub id: u64,
    pub name: RawPersonName,
    pub image: Option<RawImage>,
    #[serde(rename = "primaryOccupations")]
    pub occupations: Option<Vec<String>>,
    pub media: Option<RawWorks>,
}

#[derive(Debug, Deserialize)]
pub struct RawWorks {
    pub nodes: Option<Vec<RawWork>>,
}

#[derive(Debug, Deserialize)]
pub struct RawWork {
    pub title: Option<RawTitle>,
    #[serde(rename = "isAdult")]
    pub is_adult: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct RawStudioResponse {
    #[serde(rename = "Studio")]
    pub studio: RawStudio,
}

#[derive(Debug, Deserialize)]
pub struct RawStudio {
    pub id: u64,
    pub name: String,
    pub media: Option<RawStudioWorks>,
    pub favourites: Option<u32>,
    #[serde(rename = "isAnimationStudio")]
    pub is_animation_studio: Option<bool>,
    #[serde(rename = "siteUrl")]
    pub site_url: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RawStudioWorks {
    pub nodes: Option<Vec<RawSummary>>,
}
