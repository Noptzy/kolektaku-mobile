use std::collections::VecDeque;
use std::io::{self, Read};

use super::clock::Unwrapper;
use crate::download::codec::{
    AudioConfig, ParameterSets, SAMPLES_PER_FRAME, adts_frames, to_avc_frame,
};
use crate::download::ts::{ElementaryUnit, STREAM_AAC_ADTS, STREAM_H264, TsReader};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FrameKind {
    Video,
    Audio,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Frame {
    pub kind: FrameKind,
    pub decode_ticks: u64,
    pub present_ticks: u64,
    pub keyframe: bool,
    pub data: Vec<u8>,
}

pub struct FrameReader<R: Read> {
    ts: TsReader<R>,
    takes_audio: bool,
    parameters: ParameterSets,
    audio: Option<AudioConfig>,
    pending: VecDeque<Frame>,
    video_clock: Unwrapper,
    audio_clock: Unwrapper,
    last_video: u64,
    next_audio: Option<u64>,
}

impl<R: Read> FrameReader<R> {
    pub fn new(input: R, takes_audio: bool) -> Self {
        Self {
            ts: TsReader::new(input),
            takes_audio,
            parameters: ParameterSets::default(),
            audio: None,
            pending: VecDeque::new(),
            video_clock: Unwrapper::default(),
            audio_clock: Unwrapper::default(),
            last_video: 0,
            next_audio: None,
        }
    }

    pub fn parameters(&self) -> &ParameterSets {
        &self.parameters
    }

    pub fn audio_config(&self) -> Option<AudioConfig> {
        self.audio
    }

    pub fn next_frame(&mut self) -> io::Result<Option<Frame>> {
        loop {
            if let Some(frame) = self.pending.pop_front() {
                return Ok(Some(frame));
            }
            let Some(unit) = self.ts.next_unit()? else {
                return Ok(None);
            };
            match unit.stream_type {
                STREAM_H264 => self.take_video(unit),
                STREAM_AAC_ADTS if self.takes_audio => self.take_audio(unit),
                _ => {}
            }
        }
    }

    fn take_video(&mut self, unit: ElementaryUnit) {
        let Some(frame) = to_avc_frame(&unit.data, &mut self.parameters) else {
            return;
        };
        let present = unit
            .pts
            .map_or(self.last_video, |pts| self.video_clock.unwrap(pts));
        let decode = unit.dts.map_or(present, |dts| {
            let mut clock = self.video_clock.clone();
            clock.unwrap(dts)
        });
        self.last_video = present;
        self.pending.push_back(Frame {
            kind: FrameKind::Video,
            decode_ticks: decode.min(present),
            present_ticks: present,
            keyframe: frame.keyframe,
            data: frame.data,
        });
    }

    fn take_audio(&mut self, unit: ElementaryUnit) {
        let frames = adts_frames(&unit.data);
        let Some(first) = frames.first() else { return };
        let config = *self.audio.get_or_insert(first.config);
        let step = SAMPLES_PER_FRAME * 90_000 / u64::from(config.sample_rate());
        let mut ticks = unit
            .pts
            .map(|pts| self.audio_clock.unwrap(pts))
            .or(self.next_audio)
            .unwrap_or(0);
        for frame in frames {
            self.pending.push_back(Frame {
                kind: FrameKind::Audio,
                decode_ticks: ticks,
                present_ticks: ticks,
                keyframe: true,
                data: frame.data.to_vec(),
            });
            ticks += step;
        }
        self.next_audio = Some(ticks);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::download::codec::build_adts;
    use crate::download::ts::{ElementaryStream, build_packet, build_pat, build_pes, build_pmt};

    fn stream(units: &[(u16, Vec<u8>)]) -> Vec<u8> {
        let mut bytes = build_packet(0, true, &build_pat(0x1000));
        let streams = [
            ElementaryStream {
                stream_type: STREAM_H264,
                pid: 0x100,
            },
            ElementaryStream {
                stream_type: STREAM_AAC_ADTS,
                pid: 0x101,
            },
        ];
        bytes.extend(build_packet(0x1000, true, &build_pmt(&streams)));
        for (pid, unit) in units {
            for (index, chunk) in unit.chunks(184).enumerate() {
                bytes.extend(build_packet(*pid, index == 0, chunk));
            }
        }
        bytes
    }

    fn idr() -> Vec<u8> {
        vec![
            0, 0, 1, 0x67, 0x64, 0, 0x1F, 0, 0, 1, 0x68, 0xEE, 0, 0, 1, 0x65, 0x88,
        ]
    }

    #[test]
    fn video_and_audio_frames_come_with_their_times_and_settings() {
        let mut audio = build_adts(&[1; 4]);
        audio.extend(build_adts(&[2; 4]));
        let bytes = stream(&[
            (0x100, build_pes(0xE0, Some(93_000), Some(90_000), &idr())),
            (0x101, build_pes(0xC0, Some(90_000), None, &audio)),
        ]);
        let mut reader = FrameReader::new(bytes.as_slice(), true);
        let mut frames = Vec::new();
        while let Some(frame) = reader.next_frame().unwrap() {
            frames.push(frame);
        }
        let video: Vec<&Frame> = frames
            .iter()
            .filter(|f| f.kind == FrameKind::Video)
            .collect();
        let sound: Vec<&Frame> = frames
            .iter()
            .filter(|f| f.kind == FrameKind::Audio)
            .collect();
        assert_eq!(video.len(), 1);
        assert!(video[0].keyframe);
        assert_eq!(
            (video[0].decode_ticks, video[0].present_ticks),
            (90_000, 93_000)
        );
        assert_eq!(sound.len(), 2);
        assert_eq!(sound[1].decode_ticks - sound[0].decode_ticks, 1_920);
        assert!(reader.parameters().is_complete());
        assert_eq!(reader.audio_config().unwrap().sample_rate(), 48_000);
    }

    #[test]
    fn audio_in_the_video_file_can_be_left_out() {
        let bytes = stream(&[(0x101, build_pes(0xC0, Some(1), None, &build_adts(&[1; 4])))]);
        let mut reader = FrameReader::new(bytes.as_slice(), false);
        assert!(reader.next_frame().unwrap().is_none());
        assert!(reader.audio_config().is_none());
    }
}
