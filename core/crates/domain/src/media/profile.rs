use serde::{Deserialize, Serialize};

use super::{CharacterRole, ExternalLink, MediaSummary};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum ProfileKind {
    Character,
    Staff,
    Studio,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum FactKind {
    Occupations,
    Birthday,
    Died,
    Age,
    Gender,
    BloodType,
    HomeTown,
    YearsActive,
    Language,
    Nicknames,
    StudioType,
    Favourites,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProfileFact {
    pub kind: FactKind,
    pub value: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Appearance {
    pub media: MediaSummary,
    pub role: Option<CharacterRole>,
    pub characters: Vec<String>,
    pub credit: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Profile {
    pub id: u64,
    pub name: String,
    pub native_name: Option<String>,
    pub image_url: Option<String>,
    pub description: String,
    pub facts: Vec<ProfileFact>,
    pub links: Vec<ExternalLink>,
    pub appearances: Vec<Appearance>,
}

impl Profile {
    pub fn new(id: u64, name: impl Into<String>) -> Self {
        Self {
            id,
            name: name.into(),
            native_name: None,
            image_url: None,
            description: String::new(),
            facts: Vec::new(),
            links: Vec::new(),
            appearances: Vec::new(),
        }
    }
}

impl Appearance {
    pub fn new(media: MediaSummary) -> Self {
        Self {
            media,
            role: None,
            characters: Vec::new(),
            credit: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::media::{MediaId, MediaKind, MediaTitle};

    fn media() -> MediaSummary {
        MediaSummary::new(
            MediaId::new(5).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Judul"),
        )
    }

    #[test]
    fn a_new_profile_starts_with_nothing_but_a_name() {
        let profile = Profile::new(9, "Nama");
        assert_eq!(profile.id, 9);
        assert_eq!(profile.name, "Nama");
        assert!(profile.native_name.is_none());
        assert!(profile.description.is_empty());
        assert!(profile.facts.is_empty() && profile.links.is_empty());
        assert!(profile.appearances.is_empty());
    }

    #[test]
    fn a_new_appearance_has_no_role_and_no_characters() {
        let appearance = Appearance::new(media());
        assert!(appearance.role.is_none());
        assert!(appearance.characters.is_empty());
        assert!(appearance.credit.is_none());
    }

    #[test]
    fn a_profile_survives_json() {
        let mut profile = Profile::new(1, "A");
        let mut appearance = Appearance::new(media());
        appearance.role = Some(CharacterRole::Main);
        appearance.characters = vec!["Tanjiro".into()];
        profile.appearances.push(appearance);
        let json = serde_json::to_string(&profile).unwrap();
        assert_eq!(serde_json::from_str::<Profile>(&json).unwrap(), profile);
    }
}
