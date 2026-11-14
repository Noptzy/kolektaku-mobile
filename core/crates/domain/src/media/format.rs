use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum MediaFormat {
    Tv,
    TvShort,
    Movie,
    Special,
    Ova,
    Ona,
    Music,
    Manga,
    Novel,
    OneShot,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_catalog_names_in_json() {
        assert_eq!(
            serde_json::to_string(&MediaFormat::TvShort).unwrap(),
            "\"TV_SHORT\""
        );
        assert_eq!(
            serde_json::from_str::<MediaFormat>("\"ONE_SHOT\"").unwrap(),
            MediaFormat::OneShot
        );
    }
}
