use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum MediaOrigin {
    Original,
    Manga,
    LightNovel,
    VisualNovel,
    VideoGame,
    Novel,
    WebNovel,
    Other,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_catalog_names_in_json() {
        assert_eq!(
            serde_json::to_string(&MediaOrigin::LightNovel).unwrap(),
            "\"LIGHT_NOVEL\""
        );
        assert_eq!(
            serde_json::from_str::<MediaOrigin>("\"VIDEO_GAME\"").unwrap(),
            MediaOrigin::VideoGame
        );
    }

    #[test]
    fn an_unknown_name_is_refused() {
        assert!(serde_json::from_str::<MediaOrigin>("\"COMIC_STRIP\"").is_err());
    }
}
