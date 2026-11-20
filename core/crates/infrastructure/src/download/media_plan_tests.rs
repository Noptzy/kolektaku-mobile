use std::sync::Arc;

use domain::error::SourceError;
use domain::settings::QualityPreference;
use domain::stream::{StreamKind, StreamSet, StreamSource};

use super::media_plan::{MediaPlan, plan_media};
use crate::http::{FakeHttp, HttpResponse};

const MASTER: &str = "#EXTM3U\n#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aud\",NAME=\"Japanese\",DEFAULT=YES,URI=\"aud/index.m3u8\"\n\
#EXT-X-STREAM-INF:BANDWIDTH=900000,RESOLUTION=640x360,AUDIO=\"aud\"\n360/index.m3u8\n\
#EXT-X-STREAM-INF:BANDWIDTH=3000000,RESOLUTION=1280x720,AUDIO=\"aud\"\n720/index.m3u8\n";
const MEDIA: &str = "#EXTM3U\n#EXTINF:5.0,\nseg_000.ts\n#EXTINF:5.0,\nseg_001.ts\n";

fn source(kind: StreamKind, url: &str, quality: u32) -> StreamSource {
    StreamSource {
        url: url.into(),
        kind,
        quality,
        label: String::new(),
        is_default: false,
    }
}

fn set(sources: Vec<StreamSource>) -> StreamSet {
    StreamSet {
        sources,
        poster_url: None,
        headers: vec![("referer".into(), "https://site.test/".into())],
        subtitles: Vec::new(),
        skips: Vec::new(),
    }
}

#[tokio::test]
async fn a_master_playlist_gives_the_chosen_picture_and_its_separate_sound() {
    let http = Arc::new(FakeHttp::replying(|request| {
        let body = match request.url.as_str() {
            "https://hls.test/master.m3u8" => MASTER,
            "https://hls.test/720/index.m3u8" | "https://hls.test/aud/index.m3u8" => MEDIA,
            _ => return Ok(HttpResponse::new(404, "")),
        };
        Ok(HttpResponse::new(200, body))
    }));
    let stream = set(vec![source(
        StreamKind::Hls,
        "https://hls.test/master.m3u8",
        0,
    )]);
    let plan = plan_media(http.as_ref(), &stream, QualityPreference::P720)
        .await
        .unwrap();
    let MediaPlan::Hls {
        video,
        audio,
        resolution,
    } = plan
    else {
        panic!("expected hls")
    };
    assert_eq!(resolution, (1280, 720));
    assert_eq!(video.segments[0].url, "https://hls.test/720/seg_000.ts");
    assert_eq!(
        audio.unwrap().segments[1].url,
        "https://hls.test/aud/seg_001.ts"
    );
    assert_eq!(http.requests()[0].headers[0].0, "referer");
}

#[tokio::test]
async fn plain_files_are_saved_as_they_are_at_the_best_allowed_quality() {
    let http = FakeHttp::always(HttpResponse::new(404, ""));
    let stream = set(vec![
        source(StreamKind::Mp4, "https://v.test/480.mp4", 480),
        source(StreamKind::Mp4, "https://v.test/1080.mp4", 1080),
        source(StreamKind::Mp4, "https://v.test/720.mp4", 720),
    ]);
    let plan = plan_media(&http, &stream, QualityPreference::P720)
        .await
        .unwrap();
    assert_eq!(
        plan,
        MediaPlan::File {
            url: "https://v.test/720.mp4".into()
        }
    );
}

#[tokio::test]
async fn an_episode_without_video_is_not_found() {
    let outcome = plan_media(
        &FakeHttp::always(HttpResponse::new(404, "")),
        &set(Vec::new()),
        QualityPreference::Auto,
    )
    .await;
    assert!(matches!(outcome, Err(SourceError::NotFound(_))));
}
