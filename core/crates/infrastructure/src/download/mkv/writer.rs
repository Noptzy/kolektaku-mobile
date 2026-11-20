use std::io::{self, Seek, SeekFrom, Write};

use super::cluster::Cluster;
use super::ebml::{
    element, fixed_size, fixed_uint_element, float_element, id_bytes, text_element, uint_element,
    void,
};
use super::ids;
use super::tracks::{TrackSpec, tracks_element};

const SEEK_HEAD_SPACE: usize = 96;
const APP_NAME: &str = "Kolektaku";

pub struct MkvWriter<W: Write + Seek> {
    out: W,
    segment_size_at: u64,
    data_start: u64,
    seek_head_at: u64,
    duration_at: u64,
    info_at: u64,
    tracks_at: u64,
    video_track: Option<u64>,
    cluster: Option<Cluster>,
    cues: Vec<(u64, u64)>,
}

fn ebml_header() -> Vec<u8> {
    let mut body = uint_element(ids::EBML_VERSION, 1);
    body.extend(uint_element(ids::EBML_READ_VERSION, 1));
    body.extend(uint_element(ids::EBML_MAX_ID_LENGTH, 4));
    body.extend(uint_element(ids::EBML_MAX_SIZE_LENGTH, 8));
    body.extend(text_element(ids::DOC_TYPE, "matroska"));
    body.extend(uint_element(ids::DOC_TYPE_VERSION, 4));
    body.extend(uint_element(ids::DOC_TYPE_READ_VERSION, 2));
    element(ids::EBML, &body)
}

fn info_parts() -> (Vec<u8>, Vec<u8>) {
    let mut before = uint_element(ids::TIMESTAMP_SCALE, 1_000_000);
    before.extend(text_element(ids::MUXING_APP, APP_NAME));
    before.extend(text_element(ids::WRITING_APP, APP_NAME));
    (before, float_element(ids::DURATION, 0.0))
}

fn seek_entry(id: u32, position: u64) -> Vec<u8> {
    let mut body = element(ids::SEEK_ID, &id_bytes(id));
    body.extend(fixed_uint_element(ids::SEEK_POSITION, position));
    element(ids::SEEK, &body)
}

impl<W: Write + Seek> MkvWriter<W> {
    pub fn start(mut out: W, tracks: &[TrackSpec]) -> io::Result<Self> {
        out.write_all(&ebml_header())?;
        out.write_all(&id_bytes(ids::SEGMENT))?;
        let segment_size_at = out.stream_position()?;
        out.write_all(&fixed_size(0, 8))?;
        let data_start = out.stream_position()?;
        out.write_all(&void(SEEK_HEAD_SPACE))?;
        let info_at = out.stream_position()? - data_start;
        let (before, duration) = info_parts();
        let mut info_body = before.clone();
        info_body.extend(&duration);
        let info = element(ids::INFO, &info_body);
        let header_length = (info.len() - info_body.len()) as u64;
        let duration_at = data_start + info_at + header_length + before.len() as u64 + 3;
        out.write_all(&info)?;
        let tracks_at = out.stream_position()? - data_start;
        out.write_all(&tracks_element(tracks))?;
        let video_track = tracks
            .iter()
            .find(|track| matches!(track.kind, super::tracks::TrackKind::Video { .. }))
            .map(|track| track.number);
        Ok(Self {
            out,
            segment_size_at,
            data_start,
            seek_head_at: data_start,
            duration_at,
            info_at,
            tracks_at,
            video_track,
            cluster: None,
            cues: Vec::new(),
        })
    }

    fn cluster_for(&mut self, time_ms: i64, video_keyframe: bool) -> io::Result<&mut Cluster> {
        let needs_new = self
            .cluster
            .as_ref()
            .is_none_or(|cluster| cluster.wants_new(time_ms, video_keyframe));
        if needs_new {
            self.flush_cluster()?;
            self.cluster = Some(Cluster::open(time_ms, video_keyframe));
        }
        Ok(self.cluster.as_mut().expect("a cluster was just opened"))
    }

    fn flush_cluster(&mut self) -> io::Result<()> {
        let Some(cluster) = self.cluster.take() else {
            return Ok(());
        };
        let position = self.out.stream_position()? - self.data_start;
        if cluster.opened_by_keyframe {
            self.cues.push((cluster.start_ms as u64, position));
        }
        self.out.write_all(&cluster.into_bytes())
    }

    pub fn write_frame(
        &mut self,
        track: u64,
        time_ms: i64,
        keyframe: bool,
        data: &[u8],
    ) -> io::Result<()> {
        let video_keyframe = keyframe && Some(track) == self.video_track;
        self.cluster_for(time_ms, video_keyframe)?
            .add_frame(track, time_ms, keyframe, data);
        Ok(())
    }

    pub fn write_text(
        &mut self,
        track: u64,
        time_ms: i64,
        duration_ms: u64,
        text: &str,
    ) -> io::Result<()> {
        self.cluster_for(time_ms, false)?
            .add_text(track, time_ms, duration_ms, text);
        Ok(())
    }

    fn cues_element(&self) -> Vec<u8> {
        let track = self.video_track.unwrap_or(1);
        let body: Vec<u8> = self
            .cues
            .iter()
            .flat_map(|(time, position)| {
                let mut positions = uint_element(ids::CUE_TRACK, track);
                positions.extend(uint_element(ids::CUE_CLUSTER_POSITION, *position));
                let mut point = uint_element(ids::CUE_TIME, *time);
                point.extend(element(ids::CUE_TRACK_POSITIONS, &positions));
                element(ids::CUE_POINT, &point)
            })
            .collect();
        element(ids::CUES, &body)
    }

    pub fn finish(mut self, duration_ms: f64) -> io::Result<W> {
        self.flush_cluster()?;
        let cues_at = self.out.stream_position()? - self.data_start;
        let cues = self.cues_element();
        self.out.write_all(&cues)?;
        let end = self.out.stream_position()?;
        let mut seeks = seek_entry(ids::INFO, self.info_at);
        seeks.extend(seek_entry(ids::TRACKS, self.tracks_at));
        seeks.extend(seek_entry(ids::CUES, cues_at));
        let mut head = element(ids::SEEK_HEAD, &seeks);
        head.extend(void(SEEK_HEAD_SPACE - head.len()));
        self.out.seek(SeekFrom::Start(self.seek_head_at))?;
        self.out.write_all(&head)?;
        self.out.seek(SeekFrom::Start(self.segment_size_at))?;
        self.out.write_all(&fixed_size(end - self.data_start, 8))?;
        self.out.seek(SeekFrom::Start(self.duration_at))?;
        self.out.write_all(&duration_ms.to_be_bytes())?;
        self.out.seek(SeekFrom::Start(end))?;
        self.out.flush()?;
        Ok(self.out)
    }
}
