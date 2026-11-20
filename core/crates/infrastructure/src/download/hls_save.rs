use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};

use domain::download::DownloadPhase;
use domain::error::SourceError;

use super::episode::EpisodeDownloader;
use super::files::unique_path;
use super::hls::MediaPlaylist;
use super::mux::{RemuxJob, SubtitleInput, remux};
use super::segments::{SegmentBatch, fetch_segments};
use super::session::Session;
use super::subtitle_plan::plan_subtitles;
use super::subtitles::SubtitleFetch;

const FETCH_SHARE: f32 = 0.85;
const MUX_START: f32 = 0.88;

pub struct HlsPieces {
    pub video: MediaPlaylist,
    pub audio: Option<MediaPlaylist>,
    pub resolution: (u32, u32),
}

async fn fetch_playlist(
    downloader: &EpisodeDownloader,
    session: &Session<'_>,
    playlist: &MediaPlaylist,
    output: &Path,
    on_segment: &(dyn Fn(u64) + Send + Sync),
) -> Result<(), SourceError> {
    let batch = SegmentBatch {
        fetcher: downloader.bytes.clone(),
        urls: playlist
            .segments
            .iter()
            .map(|segment| segment.url.clone())
            .collect(),
        headers: session.headers(),
        output,
        cancel: session.cancel.clone(),
    };
    fetch_segments(batch, on_segment).await.map(|_| ())
}

async fn subtitles(downloader: &EpisodeDownloader, session: &Session<'_>) -> Vec<SubtitleInput> {
    let order = session.order;
    let Some(plan) = plan_subtitles(
        &order.job.stream.subtitles,
        order.settings.subtitles,
        order.language,
    ) else {
        return Vec::new();
    };
    let fetch = SubtitleFetch {
        http: downloader.http.clone(),
        translator: downloader.translator.clone(),
        headers: session.headers(),
    };
    fetch.inputs(&plan).await
}

async fn fetch_all(
    downloader: &EpisodeDownloader,
    session: &Session<'_>,
    pieces: &HlsPieces,
    work: &Path,
) -> Result<u64, SourceError> {
    let total = pieces.video.segments.len()
        + pieces
            .audio
            .as_ref()
            .map_or(0, |audio| audio.segments.len());
    let done = AtomicU64::new(0);
    let bytes = AtomicU64::new(0);
    let on_segment = |size: u64| {
        let count = done.fetch_add(1, Ordering::SeqCst) + 1;
        let written = bytes.fetch_add(size, Ordering::SeqCst) + size;
        session.report(
            DownloadPhase::Fetching,
            count as f32 / total.max(1) as f32 * FETCH_SHARE,
            written,
        );
    };
    fetch_playlist(
        downloader,
        session,
        &pieces.video,
        &work.join("video.ts"),
        &on_segment,
    )
    .await?;
    if let Some(audio) = &pieces.audio {
        fetch_playlist(
            downloader,
            session,
            audio,
            &work.join("audio.ts"),
            &on_segment,
        )
        .await?;
    }
    Ok(bytes.load(Ordering::SeqCst))
}

pub async fn save_hls(
    downloader: &EpisodeDownloader,
    session: &Session<'_>,
    pieces: HlsPieces,
    work: &Path,
) -> Result<String, SourceError> {
    let written = fetch_all(downloader, session, &pieces, work).await?;
    session.check_stopped()?;
    session.report(DownloadPhase::Subtitles, FETCH_SHARE, written);
    let subtitles = subtitles(downloader, session).await;
    session.check_stopped()?;
    session.report(DownloadPhase::Muxing, MUX_START, written);
    let output = unique_path(&downloader.output_folder()?, &session.file_stem(), "mkv");
    let sink = session.progress.clone();
    let (target, folder) = (output.clone(), work.to_path_buf());
    let expected_ms = pieces.video.duration() * 1000.0;
    let has_audio = pieces.audio.is_some();
    let outcome = tokio::task::spawn_blocking(move || {
        let audio: PathBuf = folder.join("audio.ts");
        let job = RemuxJob {
            video: &folder.join("video.ts"),
            audio: has_audio.then_some(audio.as_path()),
            subtitles: &subtitles,
            resolution: pieces.resolution,
            output: &target,
            expected_ms,
        };
        remux(&job, &mut |fraction| {
            let overall = MUX_START + fraction * (1.0 - MUX_START) * 0.99;
            sink(application::downloads::DownloadProgress {
                phase: DownloadPhase::Muxing,
                fraction: overall,
                bytes: written,
            });
        })
    })
    .await
    .map_err(|error| SourceError::Unavailable(error.to_string()))?;
    if let Err(error) = outcome {
        let _ = tokio::fs::remove_file(&output).await;
        return Err(error);
    }
    Ok(output.to_string_lossy().into_owned())
}
