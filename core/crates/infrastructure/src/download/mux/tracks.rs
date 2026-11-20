use application::streaming::Cue;

use crate::download::codec::AudioConfig;
use crate::download::mkv::{TrackKind, TrackSpec};

#[derive(Debug, Clone, PartialEq)]
pub struct SubtitleInput {
    pub language: Option<String>,
    pub name: String,
    pub default: bool,
    pub cues: Vec<Cue>,
}

pub fn build_tracks(
    video_private: Vec<u8>,
    resolution: (u32, u32),
    audio: Option<AudioConfig>,
    subtitles: &[SubtitleInput],
) -> Vec<TrackSpec> {
    let mut tracks = vec![TrackSpec {
        number: 1,
        kind: TrackKind::Video {
            width: resolution.0,
            height: resolution.1,
        },
        codec_id: "V_MPEG4/ISO/AVC",
        codec_private: Some(video_private),
        language: None,
        name: None,
        default: true,
    }];
    if let Some(config) = audio {
        tracks.push(TrackSpec {
            number: 2,
            kind: TrackKind::Audio {
                sample_rate: config.sample_rate(),
                channels: config.channels.max(1),
            },
            codec_id: "A_AAC",
            codec_private: Some(config.codec_private()),
            language: None,
            name: None,
            default: true,
        });
    }
    for (index, subtitle) in subtitles.iter().enumerate() {
        tracks.push(TrackSpec {
            number: 3 + index as u64,
            kind: TrackKind::Subtitle,
            codec_id: "S_TEXT/UTF8",
            codec_private: None,
            language: subtitle.language.clone(),
            name: Some(subtitle.name.clone()),
            default: subtitle.default,
        });
    }
    tracks
}

#[cfg(test)]
mod tests {
    use super::*;

    fn subtitle(name: &str, default: bool) -> SubtitleInput {
        SubtitleInput {
            language: Some("id".into()),
            name: name.into(),
            default,
            cues: Vec::new(),
        }
    }

    #[test]
    fn video_comes_first_then_audio_then_each_subtitle() {
        let audio = AudioConfig {
            object_type: 2,
            rate_index: 4,
            channels: 2,
        };
        let tracks = build_tracks(
            vec![1],
            (1280, 720),
            Some(audio),
            &[subtitle("Indonesia", true), subtitle("Inggris", false)],
        );
        let numbers: Vec<u64> = tracks.iter().map(|track| track.number).collect();
        assert_eq!(numbers, vec![1, 2, 3, 4]);
        assert_eq!(
            tracks[1].kind,
            TrackKind::Audio {
                sample_rate: 44_100,
                channels: 2
            }
        );
        assert!(tracks[2].default && !tracks[3].default);
        assert_eq!(tracks[3].name.as_deref(), Some("Inggris"));
    }

    #[test]
    fn subtitles_keep_their_numbers_even_without_sound() {
        let tracks = build_tracks(vec![1], (640, 360), None, &[subtitle("A", true)]);
        assert_eq!(tracks.len(), 2);
        assert_eq!(tracks[1].number, 3);
    }
}
