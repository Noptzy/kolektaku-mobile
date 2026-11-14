use domain::media::{ProfileKind, ProfileSummary};

use super::profile::ProfileKindDto;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProfileSummaryDto {
    pub kind: ProfileKindDto,
    pub id: u64,
    pub name: String,
    pub image_url: Option<String>,
    pub subtitle: Option<String>,
}

impl From<ProfileKind> for ProfileKindDto {
    fn from(kind: ProfileKind) -> Self {
        match kind {
            ProfileKind::Character => Self::Character,
            ProfileKind::Staff => Self::Staff,
            ProfileKind::Studio => Self::Studio,
        }
    }
}

impl From<&ProfileSummary> for ProfileSummaryDto {
    fn from(summary: &ProfileSummary) -> Self {
        Self {
            kind: summary.kind.into(),
            id: summary.id,
            name: summary.name.clone(),
            image_url: summary.image_url.clone(),
            subtitle: summary.subtitle.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_search_hit_keeps_every_field() {
        let mut summary = ProfileSummary::new(ProfileKind::Staff, 9, "Nama");
        summary.image_url = Some("https://img.test/a.jpg".into());
        summary.subtitle = Some("Voice Actor".into());
        let dto = ProfileSummaryDto::from(&summary);
        assert_eq!(dto.kind, ProfileKindDto::Staff);
        assert_eq!(dto.id, 9);
        assert_eq!(dto.subtitle.as_deref(), Some("Voice Actor"));
        assert_eq!(dto.image_url.as_deref(), Some("https://img.test/a.jpg"));
    }
}
