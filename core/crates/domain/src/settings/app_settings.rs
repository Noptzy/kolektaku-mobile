use super::accent::AccentColor;
use super::quality::QualityPreference;
use super::subtitle::{
    SubtitleBoxColor, SubtitleBoxOpacity, SubtitleColor, SubtitleEdge, SubtitleLanguage,
    SubtitleSize,
};
use super::translation::TranslationLanguage;
use crate::source::SourceId;

const PREFERS_ANIME: &str = "setting.prefers_anime";
const ANIME_SOURCE: &str = "setting.anime_source";
const SUBTITLE_LANGUAGE: &str = "setting.subtitle_language";
const SUBTITLE_SIZE: &str = "setting.subtitle_size";
const SUBTITLE_COLOR: &str = "setting.subtitle_color";
const SUBTITLE_EDGE: &str = "setting.subtitle_edge";
const SUBTITLE_BOX_COLOR: &str = "setting.subtitle_box_color";
const SUBTITLE_BOX_OPACITY: &str = "setting.subtitle_box_opacity";
const QUALITY: &str = "setting.quality";
const AUTO_NEXT: &str = "setting.auto_next";
const AUTO_SKIP: &str = "setting.auto_skip";
const ACCENT_COLOR: &str = "setting.accent_color";
const TRANSLATION_LANGUAGE: &str = "setting.translation_language";

pub const SETTING_KEYS: [&str; 13] = [
    PREFERS_ANIME,
    ANIME_SOURCE,
    SUBTITLE_LANGUAGE,
    SUBTITLE_SIZE,
    SUBTITLE_COLOR,
    SUBTITLE_EDGE,
    SUBTITLE_BOX_COLOR,
    SUBTITLE_BOX_OPACITY,
    QUALITY,
    AUTO_NEXT,
    AUTO_SKIP,
    ACCENT_COLOR,
    TRANSLATION_LANGUAGE,
];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppSettings {
    pub prefers_anime: bool,
    pub anime_source: Option<SourceId>,
    pub subtitle_language: SubtitleLanguage,
    pub subtitle_size: SubtitleSize,
    pub subtitle_color: SubtitleColor,
    pub subtitle_edge: SubtitleEdge,
    pub subtitle_box_color: SubtitleBoxColor,
    pub subtitle_box_opacity: SubtitleBoxOpacity,
    pub quality: QualityPreference,
    pub auto_next: bool,
    pub auto_skip: bool,
    pub accent: AccentColor,
    pub translation: TranslationLanguage,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            prefers_anime: true,
            anime_source: None,
            subtitle_language: SubtitleLanguage::default(),
            subtitle_size: SubtitleSize::default(),
            subtitle_color: SubtitleColor::default(),
            subtitle_edge: SubtitleEdge::default(),
            subtitle_box_color: SubtitleBoxColor::default(),
            subtitle_box_opacity: SubtitleBoxOpacity::default(),
            quality: QualityPreference::default(),
            auto_next: true,
            auto_skip: false,
            accent: AccentColor::default(),
            translation: TranslationLanguage::default(),
        }
    }
}

fn flag(value: bool) -> String {
    if value { "1" } else { "0" }.to_string()
}

fn read_flag(text: Option<String>, fallback: bool) -> bool {
    match text.as_deref() {
        Some("1") => true,
        Some("0") => false,
        _ => fallback,
    }
}

impl AppSettings {
    pub fn entries(&self) -> Vec<(&'static str, String)> {
        vec![
            (PREFERS_ANIME, flag(self.prefers_anime)),
            (
                ANIME_SOURCE,
                self.anime_source
                    .as_ref()
                    .map(ToString::to_string)
                    .unwrap_or_default(),
            ),
            (SUBTITLE_LANGUAGE, self.subtitle_language.key().to_string()),
            (SUBTITLE_SIZE, self.subtitle_size.key().to_string()),
            (SUBTITLE_COLOR, self.subtitle_color.key().to_string()),
            (SUBTITLE_EDGE, self.subtitle_edge.key().to_string()),
            (
                SUBTITLE_BOX_COLOR,
                self.subtitle_box_color.key().to_string(),
            ),
            (
                SUBTITLE_BOX_OPACITY,
                self.subtitle_box_opacity.key().to_string(),
            ),
            (QUALITY, self.quality.key().to_string()),
            (AUTO_NEXT, flag(self.auto_next)),
            (AUTO_SKIP, flag(self.auto_skip)),
            (ACCENT_COLOR, self.accent.hex()),
            (TRANSLATION_LANGUAGE, self.translation.key().to_string()),
        ]
    }

    pub fn from_lookup(lookup: impl Fn(&str) -> Option<String>) -> Self {
        let fallback = Self::default();
        let source = lookup(ANIME_SOURCE)
            .map(|text| text.trim().to_string())
            .filter(|text| !text.is_empty())
            .map(SourceId::new);
        Self {
            prefers_anime: read_flag(lookup(PREFERS_ANIME), fallback.prefers_anime),
            anime_source: source,
            subtitle_language: lookup(SUBTITLE_LANGUAGE)
                .and_then(|text| SubtitleLanguage::parse(&text))
                .unwrap_or(fallback.subtitle_language),
            subtitle_size: lookup(SUBTITLE_SIZE)
                .and_then(|text| SubtitleSize::parse(&text))
                .unwrap_or(fallback.subtitle_size),
            subtitle_color: lookup(SUBTITLE_COLOR)
                .and_then(|text| SubtitleColor::parse(&text))
                .unwrap_or(fallback.subtitle_color),
            subtitle_edge: lookup(SUBTITLE_EDGE)
                .and_then(|text| SubtitleEdge::parse(&text))
                .unwrap_or(fallback.subtitle_edge),
            subtitle_box_color: lookup(SUBTITLE_BOX_COLOR)
                .and_then(|text| SubtitleBoxColor::parse(&text))
                .unwrap_or(fallback.subtitle_box_color),
            subtitle_box_opacity: lookup(SUBTITLE_BOX_OPACITY)
                .and_then(|text| SubtitleBoxOpacity::parse(&text))
                .unwrap_or(fallback.subtitle_box_opacity),
            quality: lookup(QUALITY)
                .and_then(|text| QualityPreference::parse(&text))
                .unwrap_or(fallback.quality),
            auto_next: read_flag(lookup(AUTO_NEXT), fallback.auto_next),
            auto_skip: read_flag(lookup(AUTO_SKIP), fallback.auto_skip),
            accent: lookup(ACCENT_COLOR)
                .and_then(|text| AccentColor::parse(&text))
                .unwrap_or(fallback.accent),
            translation: lookup(TRANSLATION_LANGUAGE)
                .and_then(|text| TranslationLanguage::parse(&text))
                .unwrap_or(fallback.translation),
        }
    }
}
