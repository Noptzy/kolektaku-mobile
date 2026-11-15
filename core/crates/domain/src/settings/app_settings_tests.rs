use std::collections::HashMap;

use super::accent::AccentColor;
use super::app_settings::{AppSettings, SETTING_KEYS};
use super::quality::QualityPreference;
use super::subtitle::{
    SubtitleBoxColor, SubtitleBoxOpacity, SubtitleColor, SubtitleEdge, SubtitleLanguage,
    SubtitleSize,
};
use crate::source::SourceId;

fn lookup_of(entries: Vec<(&'static str, String)>) -> impl Fn(&str) -> Option<String> {
    let map: HashMap<&str, String> = entries.into_iter().collect();
    move |key| map.get(key).cloned()
}

fn changed() -> AppSettings {
    AppSettings {
        prefers_anime: false,
        anime_source: Some(SourceId::new("second")),
        subtitle_language: SubtitleLanguage::English,
        subtitle_size: SubtitleSize::Huge,
        subtitle_color: SubtitleColor::Yellow,
        subtitle_edge: SubtitleEdge::Outline,
        subtitle_box_color: SubtitleBoxColor::Navy,
        subtitle_box_opacity: SubtitleBoxOpacity::Medium,
        quality: QualityPreference::P720,
        auto_next: false,
        auto_skip: true,
        accent: AccentColor::parse("#1E90FF").unwrap(),
    }
}

#[test]
fn nothing_stored_means_the_defaults() {
    let settings = AppSettings::from_lookup(|_| None);
    assert_eq!(settings, AppSettings::default());
    assert!(settings.prefers_anime && settings.auto_next && !settings.auto_skip);
    assert_eq!(settings.anime_source, None);
}

#[test]
fn every_field_survives_a_round_trip() {
    let restored = AppSettings::from_lookup(lookup_of(changed().entries()));
    assert_eq!(restored, changed());
}

#[test]
fn broken_values_fall_back_one_by_one() {
    let restored = AppSettings::from_lookup(|key| match key {
        "setting.prefers_anime" => Some("maybe".into()),
        "setting.subtitle_language" => Some("klingon".into()),
        "setting.subtitle_color" => Some("purple".into()),
        "setting.subtitle_edge" => Some("glow".into()),
        "setting.subtitle_box_opacity" => Some("full".into()),
        "setting.quality" => Some("720".into()),
        "setting.anime_source" => Some("   ".into()),
        "setting.accent_color" => Some("notacolor".into()),
        _ => None,
    });
    assert!(restored.prefers_anime);
    assert_eq!(restored.subtitle_language, SubtitleLanguage::Indonesian);
    assert_eq!(restored.subtitle_color, SubtitleColor::White);
    assert_eq!(restored.subtitle_edge, SubtitleEdge::Outline);
    assert_eq!(restored.subtitle_box_opacity, SubtitleBoxOpacity::Full);
    assert_eq!(restored.quality, QualityPreference::P720);
    assert_eq!(restored.anime_source, None);
    assert_eq!(restored.accent, AccentColor::default());
}

#[test]
fn the_entries_cover_exactly_the_declared_keys() {
    let keys: Vec<&str> = AppSettings::default()
        .entries()
        .iter()
        .map(|(key, _)| *key)
        .collect();
    assert_eq!(keys, SETTING_KEYS.to_vec());
    assert!(keys.iter().all(|key| key.starts_with("setting.")));
}

#[test]
fn old_stored_background_values_are_ignored_without_harm() {
    let restored = AppSettings::from_lookup(|key| match key {
        "setting.subtitle_background" => Some("box".into()),
        _ => None,
    });
    assert_eq!(restored.subtitle_box_opacity, SubtitleBoxOpacity::Off);
    assert_eq!(restored.subtitle_edge, SubtitleEdge::Outline);
}
