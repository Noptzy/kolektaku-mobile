use application::ports::MetadataCatalog;
use application::reading::{OpenChapter, OpenNovelChapter};
use application::streaming::OpenEpisode;
use domain::source::SourceId;

use crate::dto::media::MediaRefDto;
use crate::dto::novel::NovelChapterDto;
use crate::dto::stream::{ChapterViewDto, PlaybackDto, StreamPlanDto, StreamSetDto};
use crate::error::BridgeError;
use crate::state::AppState;

fn ids(sources: Vec<String>) -> Vec<SourceId> {
    sources.into_iter().map(SourceId::new).collect()
}

pub async fn open_episode<C: MetadataCatalog>(
    state: &AppState<C>,
    target: &MediaRefDto,
    episode: f64,
    preferred: Option<String>,
    exclude: Vec<String>,
    audio: Option<String>,
) -> Result<PlaybackDto, BridgeError> {
    let open = OpenEpisode::new(
        state.links.clone(),
        state.directory.clone(),
        state.health.clone(),
    );
    let preferred = preferred.map(SourceId::new);
    let playback = open
        .execute_audio(
            &target.require()?,
            episode,
            preferred.as_ref(),
            &ids(exclude),
            audio.as_deref(),
        )
        .await?;
    Ok(PlaybackDto::from(&playback))
}

pub async fn stream_plan<C: MetadataCatalog>(
    state: &AppState<C>,
    source: &str,
    episode_id: String,
    server: String,
) -> Result<StreamPlanDto, BridgeError> {
    let video = state.directory.video(&SourceId::new(source))?;
    Ok(StreamPlanDto::from(
        &video.stream_plan(episode_id, server).await?,
    ))
}

pub fn parse_stream_payload<C: MetadataCatalog>(
    state: &AppState<C>,
    source: &str,
    payload: &str,
) -> Result<StreamSetDto, BridgeError> {
    let video = state.directory.video(&SourceId::new(source))?;
    Ok(StreamSetDto::from(&video.parse_stream_payload(payload)?))
}

pub async fn open_chapter<C: MetadataCatalog>(
    state: &AppState<C>,
    target: &MediaRefDto,
    chapter: f64,
    preferred: Option<String>,
    exclude: Vec<String>,
) -> Result<ChapterViewDto, BridgeError> {
    let open = OpenChapter::new(
        state.links.clone(),
        state.directory.clone(),
        state.health.clone(),
    );
    let preferred = preferred.map(SourceId::new);
    let view = open
        .execute(
            &target.require()?,
            chapter,
            preferred.as_ref(),
            &ids(exclude),
        )
        .await?;
    Ok(ChapterViewDto::from(&view))
}

pub async fn open_novel_chapter<C: MetadataCatalog>(
    state: &AppState<C>,
    target: &MediaRefDto,
    chapter: f64,
    preferred: Option<String>,
    exclude: Vec<String>,
) -> Result<NovelChapterDto, BridgeError> {
    let open = OpenNovelChapter::new(
        state.links.clone(),
        state.directory.clone(),
        state.health.clone(),
        state.translator.clone(),
    );
    let preferred = preferred.map(SourceId::new);
    let view = open
        .execute(
            &target.require()?,
            chapter,
            preferred.as_ref(),
            &ids(exclude),
            state.settings.get().translation,
        )
        .await?;
    Ok(NovelChapterDto::from_view(
        &view,
        state.translation_health.paused_until(),
    ))
}

pub async fn preload_novel_chapter<C: MetadataCatalog>(
    state: &AppState<C>,
    target: &MediaRefDto,
    chapter: f64,
    preferred: Option<String>,
) -> bool {
    open_novel_chapter(state, target, chapter, preferred, Vec::new())
        .await
        .is_ok()
}
