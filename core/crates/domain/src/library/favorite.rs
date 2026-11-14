use serde::{Deserialize, Serialize};

use crate::media::{MediaKind, MediaRef};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FavoriteInput {
    pub media: MediaRef,
    pub kind: MediaKind,
    pub title: String,
    pub cover_url: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Favorite {
    #[serde(flatten)]
    pub entry: FavoriteInput,
    pub added_at_secs: u64,
}

impl Favorite {
    pub fn added(entry: FavoriteInput, added_at_secs: u64) -> Self {
        Self {
            entry,
            added_at_secs,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::media::MediaId;

    fn input() -> FavoriteInput {
        FavoriteInput {
            media: MediaRef::catalog(MediaId::new(21519).unwrap()),
            kind: MediaKind::Anime,
            title: "Kimi no Na wa.".into(),
            cover_url: None,
        }
    }

    #[test]
    fn added_records_the_timestamp() {
        assert_eq!(Favorite::added(input(), 42).added_at_secs, 42);
    }

    #[test]
    fn json_is_flat_and_round_trips() {
        let favorite = Favorite::added(input(), 42);
        let json = serde_json::to_string(&favorite).unwrap();
        assert!(json.contains("\"title\":\"Kimi no Na wa.\""));
        assert_eq!(serde_json::from_str::<Favorite>(&json).unwrap(), favorite);
    }
}
