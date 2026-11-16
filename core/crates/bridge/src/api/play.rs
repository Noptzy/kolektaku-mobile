use crate::dto::media::MediaRefDto;
use crate::dto::novel::NovelChapterDto;
use crate::dto::stream::{ChapterViewDto, PlaybackDto, StreamPlanDto, StreamSetDto};
use crate::error::BridgeError;
use crate::service::play;
use crate::state::global;

pub async fn open_episode(
    reference: MediaRefDto,
    episode: f64,
    preferred: Option<String>,
    exclude: Vec<String>,
) -> Result<PlaybackDto, BridgeError> {
    play::open_episode(global()?, &reference, episode, preferred, exclude).await
}

pub async fn stream_plan(
    source: String,
    episode_id: String,
    server: String,
) -> Result<StreamPlanDto, BridgeError> {
    play::stream_plan(global()?, &source, episode_id, server).await
}

pub async fn parse_stream_payload(
    source: String,
    payload: String,
) -> Result<StreamSetDto, BridgeError> {
    play::parse_stream_payload(global()?, &source, &payload)
}

pub async fn open_chapter(
    reference: MediaRefDto,
    chapter: f64,
    preferred: Option<String>,
    exclude: Vec<String>,
) -> Result<ChapterViewDto, BridgeError> {
    play::open_chapter(global()?, &reference, chapter, preferred, exclude).await
}

pub async fn open_novel_chapter(
    reference: MediaRefDto,
    chapter: f64,
    preferred: Option<String>,
    exclude: Vec<String>,
) -> Result<NovelChapterDto, BridgeError> {
    play::open_novel_chapter(global()?, &reference, chapter, preferred, exclude).await
}

pub async fn preload_novel_chapter(
    reference: MediaRefDto,
    chapter: f64,
    preferred: Option<String>,
) -> Result<bool, BridgeError> {
    Ok(play::preload_novel_chapter(global()?, &reference, chapter, preferred).await)
}
