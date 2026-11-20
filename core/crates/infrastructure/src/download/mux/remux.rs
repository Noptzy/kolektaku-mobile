use std::fs::File;
use std::io::{BufReader, BufWriter};
use std::path::Path;

use application::streaming::Cue;
use domain::error::SourceError;

use super::clock::ticks_to_ms;
use super::frames::{Frame, FrameKind, FrameReader};
use super::merge::FrameMerge;
use super::tracks::{SubtitleInput, build_tracks};
use crate::download::mkv::MkvWriter;

const LOOKAHEAD_FRAMES: usize = 3_000;
const VIDEO_TRACK: u64 = 1;
const AUDIO_TRACK: u64 = 2;

pub struct RemuxJob<'a> {
    pub video: &'a Path,
    pub audio: Option<&'a Path>,
    pub subtitles: &'a [SubtitleInput],
    pub resolution: (u32, u32),
    pub output: &'a Path,
    pub expected_ms: f64,
}

fn failed(detail: impl ToString) -> SourceError {
    SourceError::Unavailable(format!("saving the video failed: {}", detail.to_string()))
}

fn open(path: &Path, takes_audio: bool) -> Result<FrameReader<BufReader<File>>, SourceError> {
    let file = File::open(path).map_err(failed)?;
    Ok(FrameReader::new(BufReader::new(file), takes_audio))
}

fn ready(merge: &FrameMerge<BufReader<File>>, wants_audio: bool) -> bool {
    let video = merge
        .readers()
        .iter()
        .any(|reader| reader.parameters().is_complete());
    let audio = merge
        .readers()
        .iter()
        .any(|reader| reader.audio_config().is_some());
    video && (audio || !wants_audio)
}

fn look_ahead(
    merge: &mut FrameMerge<BufReader<File>>,
    wants_audio: bool,
) -> Result<Vec<Frame>, SourceError> {
    let mut buffered = Vec::new();
    while !ready(merge, wants_audio) && buffered.len() < LOOKAHEAD_FRAMES {
        match merge.next_frame().map_err(failed)? {
            Some(frame) => buffered.push(frame),
            None => break,
        }
    }
    Ok(buffered)
}

struct Subtitles<'a> {
    inputs: &'a [SubtitleInput],
    next: Vec<usize>,
}

impl Subtitles<'_> {
    fn write_until(
        &mut self,
        writer: &mut MkvWriter<BufWriter<File>>,
        until_ms: i64,
    ) -> Result<(), SourceError> {
        for (index, input) in self.inputs.iter().enumerate() {
            let track = AUDIO_TRACK + 1 + index as u64;
            while let Some(cue) = input.cues.get(self.next[index]) {
                if cue.start_ms as i64 > until_ms {
                    break;
                }
                write_cue(writer, track, cue)?;
                self.next[index] += 1;
            }
        }
        Ok(())
    }
}

fn write_cue(
    writer: &mut MkvWriter<BufWriter<File>>,
    track: u64,
    cue: &Cue,
) -> Result<(), SourceError> {
    let duration = cue.end_ms.saturating_sub(cue.start_ms).max(1);
    writer
        .write_text(track, cue.start_ms as i64, duration, cue.text.trim())
        .map_err(failed)
}

pub fn remux(job: &RemuxJob, progress: &mut dyn FnMut(f32)) -> Result<(), SourceError> {
    let mut readers = vec![open(job.video, job.audio.is_none())?];
    if let Some(audio) = job.audio {
        readers.push(open(audio, true)?);
    }
    let mut merge = FrameMerge::new(readers);
    let buffered = look_ahead(&mut merge, job.audio.is_some())?;
    let video = merge
        .readers()
        .iter()
        .find_map(|reader| reader.parameters().codec_private());
    let video = video.ok_or_else(|| failed("no picture settings were found"))?;
    let audio = merge
        .readers()
        .iter()
        .find_map(|reader| reader.audio_config());
    let base = buffered
        .iter()
        .map(|frame| frame.decode_ticks)
        .min()
        .unwrap_or(0);
    let tracks = build_tracks(video, job.resolution, audio, job.subtitles);
    let output = BufWriter::new(File::create(job.output).map_err(failed)?);
    let mut writer = MkvWriter::start(output, &tracks).map_err(failed)?;
    let mut subtitles = Subtitles {
        inputs: job.subtitles,
        next: vec![0; job.subtitles.len()],
    };
    let mut last_ms = 0i64;
    let mut write =
        |frame: Frame, writer: &mut MkvWriter<BufWriter<File>>| -> Result<(), SourceError> {
            let track = match frame.kind {
                FrameKind::Video => VIDEO_TRACK,
                FrameKind::Audio if audio.is_some() => AUDIO_TRACK,
                FrameKind::Audio => return Ok(()),
            };
            subtitles.write_until(writer, ticks_to_ms(frame.decode_ticks, base))?;
            let time = ticks_to_ms(frame.present_ticks, base).max(0);
            last_ms = last_ms.max(time);
            if job.expected_ms > 0.0 {
                progress((time as f64 / job.expected_ms).clamp(0.0, 1.0) as f32);
            }
            writer
                .write_frame(track, time, frame.keyframe, &frame.data)
                .map_err(failed)
        };
    for frame in buffered {
        write(frame, &mut writer)?;
    }
    while let Some(frame) = merge.next_frame().map_err(failed)? {
        write(frame, &mut writer)?;
    }
    subtitles.write_until(&mut writer, i64::MAX)?;
    writer.finish(last_ms as f64 + 40.0).map_err(failed)?;
    progress(1.0);
    Ok(())
}
