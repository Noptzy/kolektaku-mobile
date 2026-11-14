mod app_settings;
#[cfg(test)]
mod app_settings_tests;
mod keyed;
mod quality;
mod subtitle;

pub use app_settings::{AppSettings, SETTING_KEYS};
pub use quality::QualityPreference;
pub use subtitle::{
    SubtitleBoxColor, SubtitleBoxOpacity, SubtitleColor, SubtitleEdge, SubtitleLanguage,
    SubtitleSize,
};
