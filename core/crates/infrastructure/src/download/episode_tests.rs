use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use application::downloads::{CancelToken, DownloadOrder, DownloadProgress, MediaDownloader};
use application::testing::FakeTranslator;
use domain::download::{
    DownloadJob, DownloadPhase, DownloadSettings, DownloadSubtitles, DownloadTarget,
};
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::settings::{QualityPreference, TranslationLanguage};
use domain::stream::{StreamKind, StreamSet, StreamSource};

use super::episode::EpisodeDownloader;
use super::fake_bytes::FakeBytes;
use super::sample_media::{audio_ts, video_ts};
use crate::http::{FakeHttp, HttpResponse};

const MASTER: &str = "#EXTM3U\n#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aud\",NAME=\"Japanese\",DEFAULT=YES,URI=\"aud/index.m3u8\"\n\
#EXT-X-STREAM-INF:BANDWIDTH=900000,RESOLUTION=640x360,AUDIO=\"aud\"\n360/index.m3u8\n";
const VIDEO: &str = "#EXTM3U\n#EXTINF:3.0,\nv0.ts\n";
const AUDIO: &str = "#EXTM3U\n#EXTINF:3.0,\na0.ts\n";

fn folder(name: &str) -> PathBuf {
    let path =
        std::env::temp_dir().join(format!("kolektaku-episode-{name}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&path);
    path
}

fn order(kind: StreamKind, url: &str) -> DownloadOrder {
    let target = DownloadTarget {
        media: MediaRef::catalog(MediaId::new(3).unwrap()),
        kind: MediaKind::Anime,
        title: "Judul".into(),
        episode: 2.0,
        cover_url: None,
    };
    let source = StreamSource {
        url: url.into(),
        kind,
        quality: 720,
        label: String::new(),
        is_default: true,
    };
    let stream = StreamSet {
        sources: vec![source],
        poster_url: None,
        headers: Vec::new(),
        subtitles: Vec::new(),
        skips: Vec::new(),
    };
    let mut job = DownloadJob::queued(target, stream, 1);
    job.id = 9;
    DownloadOrder {
        job,
        settings: DownloadSettings {
            subtitles: DownloadSubtitles::Off,
            quality: QualityPreference::P720,
        },
        language: TranslationLanguage::Indonesian,
    }
}

fn downloader(root: &std::path::Path, bytes: FakeBytes) -> EpisodeDownloader {
    let http = FakeHttp::replying(|request| {
        let body = match request.url.as_str() {
            "https://hls.test/master.m3u8" => MASTER,
            "https://hls.test/360/index.m3u8" => VIDEO,
            "https://hls.test/aud/index.m3u8" => AUDIO,
            _ => return Ok(HttpResponse::new(404, "")),
        };
        Ok(HttpResponse::new(200, body))
    });
    EpisodeDownloader::new(
        Arc::new(http),
        Arc::new(bytes),
        Arc::new(FakeTranslator::prefixing("")),
        root.join("out"),
    )
}

#[tokio::test]
async fn an_hls_episode_is_fetched_joined_and_saved_as_one_named_file() {
    let root = folder("hls");
    let bytes = FakeBytes::default()
        .with("https://hls.test/360/v0.ts", Ok(video_ts()))
        .with("https://hls.test/aud/a0.ts", Ok(audio_ts()));
    let downloader = downloader(&root, bytes);
    let steps: Arc<Mutex<Vec<DownloadProgress>>> = Arc::default();
    let seen = steps.clone();
    let path = downloader
        .download(
            order(StreamKind::Hls, "https://hls.test/master.m3u8"),
            Arc::new(move |step| seen.lock().unwrap().push(step)),
            CancelToken::default(),
        )
        .await
        .unwrap();
    assert!(path.ends_with("Judul - Episode 02.mkv"));
    assert!(std::fs::metadata(&path).unwrap().len() > 100);
    assert!(!root.join("out").join(".parts").join("job-9").exists());
    let phases: Vec<DownloadPhase> = steps
        .lock()
        .unwrap()
        .iter()
        .map(|step| step.phase)
        .collect();
    assert!(phases.contains(&DownloadPhase::Fetching) && phases.contains(&DownloadPhase::Muxing));
    let _ = std::fs::remove_dir_all(&root);
}

#[tokio::test]
async fn a_plain_video_file_is_saved_directly() {
    let root = folder("file");
    let bytes = FakeBytes::default().with("https://v.test/ep.mp4", Ok(vec![1, 2, 3]));
    let downloader = downloader(&root, bytes);
    let path = downloader
        .download(
            order(StreamKind::Mp4, "https://v.test/ep.mp4"),
            Arc::new(|_| {}),
            CancelToken::default(),
        )
        .await
        .unwrap();
    assert!(path.ends_with("Judul - Episode 02.mp4"));
    assert_eq!(std::fs::read(&path).unwrap(), vec![1, 2, 3]);
    downloader.discard(path.clone()).await;
    assert!(!std::path::Path::new(&path).exists());
    let _ = std::fs::remove_dir_all(&root);
}

#[tokio::test]
async fn a_failed_segment_leaves_no_half_file_behind() {
    let root = folder("broken");
    let downloader = downloader(&root, FakeBytes::default());
    let outcome = downloader
        .download(
            order(StreamKind::Hls, "https://hls.test/master.m3u8"),
            Arc::new(|_| {}),
            CancelToken::default(),
        )
        .await;
    assert!(outcome.is_err());
    assert!(!root.join("out").join(".parts").join("job-9").exists());
    let saved = std::fs::read_dir(root.join("out"))
        .map(|entries| {
            entries
                .flatten()
                .filter(|entry| entry.path().is_file())
                .count()
        })
        .unwrap_or(0);
    assert_eq!(saved, 0);
    let _ = std::fs::remove_dir_all(&root);
}
