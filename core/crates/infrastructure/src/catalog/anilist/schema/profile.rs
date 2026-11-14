use domain::media::CharacterRole;
use serde::Deserialize;

use super::credits::RawName;
use super::lenient::lenient;
use super::summary::{RawDate, RawImage, RawSummary};

#[derive(Debug, Deserialize)]
pub struct RawProfileResponse {
    #[serde(rename = "Character", alias = "Staff")]
    pub profile: RawProfile,
}

#[derive(Debug, Deserialize)]
pub struct RawProfileName {
    pub full: Option<String>,
    pub native: Option<String>,
    pub alternative: Option<Vec<String>>,
}

#[derive(Debug, Deserialize)]
pub struct RawProfile {
    pub id: u64,
    pub name: RawProfileName,
    pub image: Option<RawImage>,
    pub description: Option<String>,
    #[serde(alias = "characterMedia")]
    pub media: Option<RawAppearances>,
    #[serde(rename = "staffMedia")]
    pub staff_media: Option<RawAppearances>,
    #[serde(rename = "primaryOccupations")]
    pub occupations: Option<Vec<String>>,
    pub gender: Option<String>,
    #[serde(rename = "dateOfBirth")]
    pub date_of_birth: Option<RawDate>,
    #[serde(rename = "dateOfDeath")]
    pub date_of_death: Option<RawDate>,
    pub age: Option<serde_json::Value>,
    #[serde(rename = "yearsActive")]
    pub years_active: Option<Vec<u16>>,
    #[serde(rename = "homeTown")]
    pub home_town: Option<String>,
    #[serde(rename = "bloodType")]
    pub blood_type: Option<String>,
    #[serde(rename = "languageV2")]
    pub language: Option<String>,
    pub favourites: Option<u32>,
    #[serde(rename = "siteUrl")]
    pub site_url: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RawAppearances {
    pub edges: Option<Vec<RawAppearanceEdge>>,
}

#[derive(Debug, Deserialize)]
pub struct RawAppearanceEdge {
    #[serde(rename = "characterRole", default, deserialize_with = "lenient")]
    pub role: Option<CharacterRole>,
    pub node: Option<RawSummary>,
    pub characters: Option<Vec<RawVoicedCharacter>>,
    #[serde(rename = "staffRole")]
    pub staff_role: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RawVoicedCharacter {
    pub name: Option<RawName>,
}
