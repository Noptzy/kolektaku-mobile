use std::time::Duration;

use super::downloads;
use super::service_support::{Folder, catalog_ref, state};
use crate::dto::downloads::{
    DownloadPhaseDto, DownloadSettingsDto, DownloadSubtitlesDto, DownloadTargetDto,
};
use crate::dto::media::MediaKindDto;
use crate::dto::stream::{StreamSetDto, StreamSourceDto};

fn target(episode: f64) -> DownloadTargetDto {
    DownloadTargetDto {
        reference: catalog_ref(),
        kind: MediaKindDto::Anime,
        title: "Spy x Family".into(),
        episode,
        cover_url: None,
    }
}

fn stream(url: &str) -> StreamSetDto {
    StreamSetDto {
        sources: vec![StreamSourceDto {
            url: url.into(),
            kind: "mp4".into(),
            quality: 720,
            label: "720p".into(),
            is_default: true,
        }],
        poster_url: None,
        headers: Vec::new(),
        subtitles: Vec::new(),
        skips: Vec::new(),
    }
}

#[tokio::test]
async fn an_episode_without_any_video_is_refused() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let mut empty = stream("https://v.test/a.mp4");
    empty.sources.clear();
    assert!(
        downloads::enqueue(&state, target(1.0), empty)
            .await
            .is_err()
    );
    assert!(downloads::list(&state).is_empty());
}

#[tokio::test]
async fn a_queued_episode_is_listed_and_fails_plainly_when_offline() {
    let folder = Folder::new();
    let state = state(&folder).await;
    downloads::use_folder(
        &state,
        folder.0.join("films").to_string_lossy().into_owned(),
    );
    let job = downloads::enqueue(&state, target(2.0), stream("https://127.0.0.1:9/ep.mp4"))
        .await
        .unwrap();
    assert_eq!(job.target.title, "Spy x Family");
    let mut phase = job.phase;
    for _ in 0..400 {
        phase = downloads::list(&state)[0].phase;
        if phase == DownloadPhaseDto::Failed {
            break;
        }
        tokio::time::sleep(Duration::from_millis(10)).await;
    }
    assert_eq!(phase, DownloadPhaseDto::Failed);
    downloads::remove(&state, job.id, true).await.unwrap();
    assert!(downloads::list(&state).is_empty());
}

#[tokio::test]
async fn download_settings_are_saved_and_read_back() {
    let folder = Folder::new();
    let state = state(&folder).await;
    assert_eq!(
        downloads::settings(&state).subtitles,
        DownloadSubtitlesDto::Translated
    );
    let chosen = DownloadSettingsDto {
        subtitles: DownloadSubtitlesDto::Off,
        quality: "480".into(),
    };
    downloads::save_settings(&state, chosen.clone())
        .await
        .unwrap();
    assert_eq!(downloads::settings(&state), chosen);
}
