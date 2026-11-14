use domain::media::{Appearance, Profile, ProfileKind};

use super::links::ExternalLinkDto;
use super::media::{MediaSummaryDto, tag};
use super::profile_facts::ProfileFactDto;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProfileKindDto {
    Character,
    Staff,
    Studio,
}

impl From<ProfileKindDto> for ProfileKind {
    fn from(kind: ProfileKindDto) -> Self {
        match kind {
            ProfileKindDto::Character => Self::Character,
            ProfileKindDto::Staff => Self::Staff,
            ProfileKindDto::Studio => Self::Studio,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct AppearanceDto {
    pub media: MediaSummaryDto,
    pub role: Option<String>,
    pub characters: Vec<String>,
    pub credit: Option<String>,
}

impl From<&Appearance> for AppearanceDto {
    fn from(appearance: &Appearance) -> Self {
        Self {
            media: MediaSummaryDto::from(&appearance.media),
            role: appearance.role.as_ref().map(tag),
            characters: appearance.characters.clone(),
            credit: appearance.credit.clone(),
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct ProfileDto {
    pub id: u64,
    pub name: String,
    pub native_name: Option<String>,
    pub image_url: Option<String>,
    pub description: String,
    pub facts: Vec<ProfileFactDto>,
    pub links: Vec<ExternalLinkDto>,
    pub appearances: Vec<AppearanceDto>,
}

impl From<&Profile> for ProfileDto {
    fn from(profile: &Profile) -> Self {
        Self {
            id: profile.id,
            name: profile.name.clone(),
            native_name: profile.native_name.clone(),
            image_url: profile.image_url.clone(),
            description: profile.description.clone(),
            facts: profile.facts.iter().map(Into::into).collect(),
            links: profile.links.iter().map(Into::into).collect(),
            appearances: profile.appearances.iter().map(Into::into).collect(),
        }
    }
}

#[cfg(test)]
mod tests {
    use domain::media::{CharacterRole, MediaId, MediaKind, MediaSummary, MediaTitle};

    use super::*;

    #[test]
    fn the_kind_maps_one_to_one() {
        assert_eq!(
            ProfileKind::from(ProfileKindDto::Character),
            ProfileKind::Character
        );
        assert_eq!(ProfileKind::from(ProfileKindDto::Staff), ProfileKind::Staff);
        assert_eq!(
            ProfileKind::from(ProfileKindDto::Studio),
            ProfileKind::Studio
        );
        assert_eq!(
            ProfileKindDto::from(ProfileKind::Studio),
            ProfileKindDto::Studio
        );
    }

    #[test]
    fn a_profile_carries_its_titles_with_role_and_characters() {
        let media = MediaSummary::new(
            MediaId::new(4).unwrap(),
            MediaKind::Anime,
            MediaTitle::new("Judul"),
        );
        let mut appearance = Appearance::new(media);
        appearance.role = Some(CharacterRole::Main);
        appearance.characters = vec!["Tanjiro".into()];
        let mut profile = Profile::new(7, "Nama");
        profile.native_name = Some("名前".into());
        profile.appearances.push(appearance);
        let dto = ProfileDto::from(&profile);
        assert_eq!(dto.id, 7);
        assert_eq!(dto.native_name.as_deref(), Some("名前"));
        assert_eq!(dto.appearances[0].media.title_romaji, "Judul");
        assert_eq!(dto.appearances[0].role.as_deref(), Some("MAIN"));
        assert_eq!(dto.appearances[0].characters, vec!["Tanjiro"]);
    }

    #[test]
    fn a_title_without_a_role_has_none() {
        let media = MediaSummary::new(
            MediaId::new(4).unwrap(),
            MediaKind::Manga,
            MediaTitle::new("Judul"),
        );
        let dto = AppearanceDto::from(&Appearance::new(media));
        assert!(dto.role.is_none());
        assert!(dto.characters.is_empty());
    }
}
