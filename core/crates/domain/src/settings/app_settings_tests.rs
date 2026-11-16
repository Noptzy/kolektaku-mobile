use std::collections::HashMap;

use super::accent::AccentColor;
use super::app_settings::{AppSettings, SETTING_KEYS};
use super::quality::QualityPreference;
use super::reading_look::{ReadingSize, ReadingSpacing};
use super::subtitle::{
    SubtitleBoxColor, SubtitleBoxOpacity, SubtitleColor, SubtitleEdge, SubtitleLanguage,
    SubtitleSize,
};
use super::translation::TranslationLanguage;
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
        translation: TranslationLanguage::Japanese,
        reading_size: ReadingSize::Largest,
        reading_spacing: ReadingSpacing::Loose,
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
        "setting.translation_language" => Some("klingon".into()),
        "setting.reading_size" => Some("gigantic".into()),
        "setting.reading_spacing" => Some("loose".into()),
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
    assert_eq!(restored.translation, TranslationLanguage::Indonesian);
    assert_eq!(restored.reading_size, ReadingSize::Medium);
    assert_eq!(restored.reading_spacing, ReadingSpacing::Loose);
}

#[test]
fn translation_is_on_towards_indonesian_from_the_start() {
    let settings = AppSettings::from_lookup(|_| None);
    assert_eq!(settings.translation, TranslationLanguage::Indonesian);
}

#[test]
fn translation_can_be_switched_off_and_stays_off() {
    let restored = AppSettings::from_lookup(|key| match key {
        "setting.translation_language" => Some("off".into()),
        _ => None,
    });
    assert_eq!(restored.translation, TranslationLanguage::Off);
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

#[test]
fn reading_starts_at_the_middle_size_and_spacing() {
    let settings = AppSettings::from_lookup(|_| None);
    assert_eq!(settings.reading_size, ReadingSize::Medium);
    assert_eq!(settings.reading_spacing, ReadingSpacing::Normal);
}

#[test]
fn every_setting_has_one_stored_key() {
    let entries = AppSettings::default().entries();
    assert_eq!(entries.len(), SETTING_KEYS.len());
    for (key, _) in entries {
        assert!(SETTING_KEYS.contains(&key), "{key}");
    }
}
