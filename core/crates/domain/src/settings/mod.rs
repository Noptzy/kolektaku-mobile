mod accent;
mod app_settings;
#[cfg(test)]
mod app_settings_tests;
mod keyed;
mod quality;
mod reading_look;
mod subtitle;
mod translation;

pub use accent::AccentColor;
pub use app_settings::{AppSettings, SETTING_KEYS};
pub use quality::QualityPreference;
pub use reading_look::{ReadingSize, ReadingSpacing};
pub use subtitle::{
    SubtitleBoxColor, SubtitleBoxOpacity, SubtitleColor, SubtitleEdge, SubtitleLanguage,
    SubtitleSize,
};
pub use translation::TranslationLanguage;
