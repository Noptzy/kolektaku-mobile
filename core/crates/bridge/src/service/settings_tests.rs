use super::service_support::{Folder, state};
use super::settings;
use crate::dto::settings::{QualityDto, SettingsDto, SubtitleLanguageDto};

#[tokio::test]
async fn a_fresh_install_has_the_default_settings() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let current = settings::current(&state);
    assert!(current.prefers_anime && current.auto_next && !current.auto_skip);
    assert_eq!(current.anime_source, None);
    assert_eq!(current.subtitle_language, SubtitleLanguageDto::Indonesian);
}

#[tokio::test]
async fn saved_settings_come_back_and_survive_a_restart() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let wanted = SettingsDto {
        prefers_anime: false,
        quality: QualityDto::P480,
        subtitle_language: SubtitleLanguageDto::English,
        ..settings::current(&state)
    };
    assert_eq!(
        settings::save(&state, wanted.clone()).await.unwrap(),
        wanted
    );
    let restarted = super::service_support::state(&folder).await;
    assert_eq!(settings::current(&restarted), wanted);
}

#[tokio::test]
async fn a_preferred_anime_source_that_exists_is_kept() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let wanted = SettingsDto {
        anime_source: Some("a".into()),
        ..settings::current(&state)
    };
    let saved = settings::save(&state, wanted).await.unwrap();
    assert_eq!(saved.anime_source.as_deref(), Some("a"));
}

#[tokio::test]
async fn a_preferred_source_that_is_unknown_is_dropped() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let wanted = SettingsDto {
        anime_source: Some("ghost".into()),
        ..settings::current(&state)
    };
    let saved = settings::save(&state, wanted).await.unwrap();
    assert_eq!(saved.anime_source, None);
}
