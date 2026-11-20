use std::path::PathBuf;

use application::streaming::Cue;

use super::remux::{RemuxJob, remux};
use super::tracks::SubtitleInput;
use crate::download::sample_media::{audio_ts, video_ts};

fn folder(name: &str) -> PathBuf {
    let path = std::env::temp_dir().join(format!("kolektaku-remux-{name}-{}", std::process::id()));
    let _ = std::fs::remove_dir_all(&path);
    std::fs::create_dir_all(&path).unwrap();
    path
}

fn subtitles() -> Vec<SubtitleInput> {
    vec![SubtitleInput {
        language: Some("id".into()),
        name: "Indonesia".into(),
        default: true,
        cues: vec![Cue {
            start_ms: 500,
            end_ms: 1_500,
            text: "Halo semuanya".into(),
        }],
    }]
}

fn find(haystack: &[u8], needle: &[u8]) -> bool {
    haystack
        .windows(needle.len())
        .any(|window| window == needle)
}

#[test]
fn separate_video_and_audio_files_become_one_file_with_subtitles() {
    let dir = folder("separate");
    std::fs::write(dir.join("video.ts"), video_ts()).unwrap();
    std::fs::write(dir.join("audio.ts"), audio_ts()).unwrap();
    let output = dir.join("out.mkv");
    let subtitles = subtitles();
    let mut reported = Vec::new();
    let job = RemuxJob {
        video: &dir.join("video.ts"),
        audio: Some(&dir.join("audio.ts")),
        subtitles: &subtitles,
        resolution: (640, 360),
        output: &output,
        expected_ms: 3_000.0,
    };
    remux(&job, &mut |fraction| reported.push(fraction)).unwrap();
    let bytes = std::fs::read(&output).unwrap();
    assert!(find(&bytes, b"V_MPEG4/ISO/AVC"));
    assert!(find(&bytes, b"A_AAC"));
    assert!(find(&bytes, b"Halo semuanya"));
    assert!(find(&bytes, &[0x88, 0x01]));
    assert_eq!(reported.last().copied(), Some(1.0));
    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn a_video_file_without_picture_settings_is_refused() {
    let dir = folder("broken");
    std::fs::write(dir.join("audio.ts"), audio_ts()).unwrap();
    let job = RemuxJob {
        video: &dir.join("audio.ts"),
        audio: None,
        subtitles: &[],
        resolution: (640, 360),
        output: &dir.join("out.mkv"),
        expected_ms: 0.0,
    };
    assert!(remux(&job, &mut |_| {}).is_err());
    let _ = std::fs::remove_dir_all(&dir);
}
