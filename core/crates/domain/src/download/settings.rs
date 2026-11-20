use crate::settings::QualityPreference;

const SUBTITLES: &str = "download.subtitles";
const QUALITY: &str = "download.quality";

pub const DOWNLOAD_SETTING_KEYS: [&str; 2] = [SUBTITLES, QUALITY];

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum DownloadSubtitles {
    #[default]
    Translated,
    Original,
    Off,
}

impl DownloadSubtitles {
    pub fn key(self) -> &'static str {
        match self {
            Self::Translated => "translated",
            Self::Original => "original",
            Self::Off => "off",
        }
    }

    pub fn parse(text: &str) -> Option<Self> {
        match text {
            "translated" => Some(Self::Translated),
            "original" => Some(Self::Original),
            "off" => Some(Self::Off),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DownloadSettings {
    pub subtitles: DownloadSubtitles,
    pub quality: QualityPreference,
}

impl Default for DownloadSettings {
    fn default() -> Self {
        Self {
            subtitles: DownloadSubtitles::Translated,
            quality: QualityPreference::P720,
        }
    }
}

impl DownloadSettings {
    pub fn entries(&self) -> Vec<(&'static str, String)> {
        vec![
            (SUBTITLES, self.subtitles.key().to_string()),
            (QUALITY, self.quality.key().to_string()),
        ]
    }

    pub fn from_lookup(lookup: impl Fn(&str) -> Option<String>) -> Self {
        let fallback = Self::default();
        Self {
            subtitles: lookup(SUBTITLES)
                .and_then(|text| DownloadSubtitles::parse(&text))
                .unwrap_or(fallback.subtitles),
            quality: lookup(QUALITY)
                .and_then(|text| QualityPreference::parse(&text))
                .unwrap_or(fallback.quality),
        }
    }
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::*;

    #[test]
    fn the_default_is_translated_subtitles_at_720p() {
        let settings = DownloadSettings::default();
        assert_eq!(settings.subtitles, DownloadSubtitles::Translated);
        assert_eq!(settings.quality, QualityPreference::P720);
    }

    #[test]
    fn entries_round_trip_through_a_lookup() {
        let settings = DownloadSettings {
            subtitles: DownloadSubtitles::Off,
            quality: QualityPreference::P1080,
        };
        let stored: HashMap<&str, String> = settings.entries().into_iter().collect();
        let read = DownloadSettings::from_lookup(|key| stored.get(key).cloned());
        assert_eq!(read, settings);
        assert_eq!(DOWNLOAD_SETTING_KEYS.len(), stored.len());
    }

    #[test]
    fn unknown_values_fall_back_to_the_default() {
        let read = DownloadSettings::from_lookup(|_| Some("nonsense".into()));
        assert_eq!(read, DownloadSettings::default());
    }
}
