use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MediaKind {
    Anime,
    Manga,
    Novel,
}

impl MediaKind {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Anime => "anime",
            Self::Manga => "manga",
            Self::Novel => "novel",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn as_str_matches_serde_name() {
        for kind in [MediaKind::Anime, MediaKind::Manga, MediaKind::Novel] {
            let json = serde_json::to_string(&kind).unwrap();
            assert_eq!(json, format!("\"{}\"", kind.as_str()));
        }
    }
}
