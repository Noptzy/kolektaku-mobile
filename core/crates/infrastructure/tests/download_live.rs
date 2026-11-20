use std::sync::Arc;

use application::downloads::CancelToken;
use application::streaming::parse_vtt;
use application::translation::TranslateCues;
use domain::settings::{QualityPreference, TranslationLanguage};
use domain::stream::{StreamKind, StreamSet, StreamSource};
use domain::translation::LanguageRoute;
use infrastructure::download::mux::{RemuxJob, SubtitleInput, remux};
use infrastructure::download::{ByteFetcher, MediaPlan, SegmentBatch, fetch_segments, plan_media};
use infrastructure::http::{HttpClient, HttpRequest, ReqwestClient};
use infrastructure::translate::google::GoogleTranslator;

const SEGMENTS: usize = 6;

fn env(name: &str) -> String {
    std::env::var(name).unwrap_or_else(|_| panic!("set {name}"))
}

#[tokio::test]
#[ignore = "downloads a real episode"]
async fn the_first_seconds_of_a_real_episode_become_a_playable_file() {
    let client = Arc::new(ReqwestClient::standard().unwrap());
    let http: Arc<dyn HttpClient> = client.clone();
    let bytes: Arc<dyn ByteFetcher> = client.clone();
    let headers = vec![("referer".to_string(), env("LIVE_REFERER"))];
    let source = StreamSource {
        url: env("LIVE_MASTER"),
        kind: StreamKind::Hls,
        quality: 0,
        label: String::new(),
        is_default: true,
    };
    let set = StreamSet {
        sources: vec![source],
        poster_url: None,
        headers: headers.clone(),
        subtitles: Vec::new(),
        skips: Vec::new(),
    };
    let MediaPlan::Hls {
        mut video,
        audio,
        resolution,
    } = plan_media(http.as_ref(), &set, QualityPreference::P360)
        .await
        .unwrap()
    else {
        panic!("expected hls");
    };
    video.segments.truncate(SEGMENTS);
    let folder = std::env::temp_dir().join("kolektaku-live-download");
    let _ = std::fs::remove_dir_all(&folder);
    std::fs::create_dir_all(&folder).unwrap();
    let urls = |playlist: &infrastructure::download::hls::MediaPlaylist| -> Vec<String> {
        playlist
            .segments
            .iter()
            .take(SEGMENTS)
            .map(|segment| segment.url.clone())
            .collect()
    };
    let video_file = folder.join("video.ts");
    fetch_segments(
        SegmentBatch {
            fetcher: bytes.clone(),
            urls: urls(&video),
            headers: headers.clone(),
            output: &video_file,
            cancel: CancelToken::default(),
        },
        &|_| {},
    )
    .await
    .unwrap();
    let audio_file = folder.join("audio.ts");
    let audio = audio.unwrap();
    fetch_segments(
        SegmentBatch {
            fetcher: bytes.clone(),
            urls: urls(&audio),
            headers: headers.clone(),
            output: &audio_file,
            cancel: CancelToken::default(),
        },
        &|_| {},
    )
    .await
    .unwrap();
    let vtt = http
        .send(HttpRequest::get(env("LIVE_VTT")).with_header("referer", &env("LIVE_REFERER")))
        .await
        .unwrap();
    let cues = parse_vtt(&vtt.body);
    let route = LanguageRoute::new(Some("en"), TranslationLanguage::Indonesian).unwrap();
    let translated = TranslateCues::new(Arc::new(GoogleTranslator::new(http.clone())))
        .execute(cues.clone(), &route, 0)
        .await;
    assert!(translated.translated);
    let subtitles = vec![
        SubtitleInput {
            language: Some("id".into()),
            name: "Indonesia (terjemahan otomatis)".into(),
            default: true,
            cues: translated.cues,
        },
        SubtitleInput {
            language: Some("en".into()),
            name: "Inggris".into(),
            default: false,
            cues,
        },
    ];
    let output = folder.join("episode.mkv");
    let job = RemuxJob {
        video: &video_file,
        audio: Some(&audio_file),
        subtitles: &subtitles,
        resolution,
        output: &output,
        expected_ms: video.duration() * 1000.0,
    };
    remux(&job, &mut |_| {}).unwrap();
    println!(
        "saved {} ({} bytes) at {:?}",
        output.display(),
        std::fs::metadata(&output).unwrap().len(),
        resolution
    );
}
