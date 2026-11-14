use serde::{Deserialize, Serialize};

use super::ProfileKind;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProfileSummary {
    pub kind: ProfileKind,
    pub id: u64,
    pub name: String,
    pub image_url: Option<String>,
    pub subtitle: Option<String>,
}

impl ProfileSummary {
    pub fn new(kind: ProfileKind, id: u64, name: impl Into<String>) -> Self {
        Self {
            kind,
            id,
            name: name.into(),
            image_url: None,
            subtitle: None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_new_summary_has_only_a_name() {
        let summary = ProfileSummary::new(ProfileKind::Studio, 4, "Studio X");
        assert_eq!(summary.id, 4);
        assert!(summary.image_url.is_none() && summary.subtitle.is_none());
    }

    #[test]
    fn a_summary_survives_json() {
        let mut summary = ProfileSummary::new(ProfileKind::Staff, 1, "A");
        summary.subtitle = Some("Voice Actor".into());
        let json = serde_json::to_string(&summary).unwrap();
        assert_eq!(
            serde_json::from_str::<ProfileSummary>(&json).unwrap(),
            summary
        );
    }
}
