use std::collections::{HashMap, VecDeque};

use super::packet::read_packet;
use super::pes::parse_pes;
use super::psi::{elementary_streams, program_map_pid};

pub const STREAM_H264: u8 = 0x1B;
pub const STREAM_AAC_ADTS: u8 = 0x0F;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ElementaryUnit {
    pub stream_type: u8,
    pub pts: Option<u64>,
    pub dts: Option<u64>,
    pub data: Vec<u8>,
}

#[derive(Default)]
pub struct TsDemuxer {
    program_map: Option<u16>,
    streams: HashMap<u16, u8>,
    pending: HashMap<u16, Vec<u8>>,
    ready: VecDeque<ElementaryUnit>,
}

fn wanted(stream_type: u8) -> bool {
    matches!(stream_type, STREAM_H264 | STREAM_AAC_ADTS)
}

impl TsDemuxer {
    pub fn push(&mut self, bytes: &[u8]) {
        let Some(packet) = read_packet(bytes) else {
            return;
        };
        if packet.pid == 0 && packet.starts_unit {
            self.program_map = program_map_pid(packet.payload).or(self.program_map);
            return;
        }
        if Some(packet.pid) == self.program_map && packet.starts_unit {
            for stream in elementary_streams(packet.payload) {
                if wanted(stream.stream_type) {
                    self.streams.entry(stream.pid).or_insert(stream.stream_type);
                }
            }
            return;
        }
        if !self.streams.contains_key(&packet.pid) {
            return;
        }
        if packet.starts_unit {
            self.complete(packet.pid);
            self.pending.insert(packet.pid, packet.payload.to_vec());
        } else if let Some(buffer) = self.pending.get_mut(&packet.pid) {
            buffer.extend_from_slice(packet.payload);
        }
    }

    pub fn finish(&mut self) {
        let mut pids: Vec<u16> = self.pending.keys().copied().collect();
        pids.sort_unstable();
        for pid in pids {
            self.complete(pid);
        }
    }

    pub fn pop(&mut self) -> Option<ElementaryUnit> {
        self.ready.pop_front()
    }

    fn complete(&mut self, pid: u16) {
        let Some(buffer) = self.pending.remove(&pid) else {
            return;
        };
        let Some(stream_type) = self.streams.get(&pid).copied() else {
            return;
        };
        let Some(unit) = parse_pes(&buffer) else {
            return;
        };
        if unit.payload.is_empty() {
            return;
        }
        self.ready.push_back(ElementaryUnit {
            stream_type,
            pts: unit.pts,
            dts: unit.dts,
            data: unit.payload.to_vec(),
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::download::ts::packet::build_packet;
    use crate::download::ts::pes::build_pes;
    use crate::download::ts::psi::{ElementaryStream, build_pat, build_pmt};

    fn split_into_packets(pid: u16, unit: &[u8]) -> Vec<Vec<u8>> {
        unit.chunks(184)
            .enumerate()
            .map(|(index, chunk)| build_packet(pid, index == 0, chunk))
            .collect()
    }

    fn feed(demuxer: &mut TsDemuxer, packets: &[Vec<u8>]) {
        for packet in packets {
            demuxer.push(packet);
        }
    }

    #[test]
    fn units_of_the_video_and_audio_streams_come_out_whole_and_in_order() {
        let mut demuxer = TsDemuxer::default();
        feed(&mut demuxer, &[build_packet(0, true, &build_pat(0x1000))]);
        let streams = [
            ElementaryStream {
                stream_type: STREAM_H264,
                pid: 0x100,
            },
            ElementaryStream {
                stream_type: STREAM_AAC_ADTS,
                pid: 0x101,
            },
            ElementaryStream {
                stream_type: 0x06,
                pid: 0x102,
            },
        ];
        feed(
            &mut demuxer,
            &[build_packet(0x1000, true, &build_pmt(&streams))],
        );
        let big = vec![5u8; 500];
        feed(
            &mut demuxer,
            &split_into_packets(0x100, &build_pes(0xE0, Some(10), Some(5), &big)),
        );
        feed(
            &mut demuxer,
            &split_into_packets(0x102, &build_pes(0xBD, Some(1), None, &[1])),
        );
        feed(
            &mut demuxer,
            &split_into_packets(0x101, &build_pes(0xC0, Some(20), None, &[3; 50])),
        );
        feed(
            &mut demuxer,
            &split_into_packets(0x100, &build_pes(0xE0, Some(40), None, &[6; 10])),
        );
        demuxer.finish();
        let units: Vec<ElementaryUnit> = std::iter::from_fn(|| demuxer.pop()).collect();
        let video: Vec<&ElementaryUnit> = units
            .iter()
            .filter(|unit| unit.stream_type == STREAM_H264)
            .collect();
        let audio: Vec<&ElementaryUnit> = units
            .iter()
            .filter(|unit| unit.stream_type == STREAM_AAC_ADTS)
            .collect();
        assert_eq!(units.len(), 3);
        assert_eq!((video[0].pts, video[0].dts), (Some(10), Some(5)));
        assert_eq!(video[0].data, big);
        assert_eq!(video[1].pts, Some(40));
        assert_eq!(audio[0].pts, Some(20));
    }

    #[test]
    fn packets_before_the_program_tables_are_ignored() {
        let mut demuxer = TsDemuxer::default();
        feed(
            &mut demuxer,
            &split_into_packets(0x100, &build_pes(0xE0, Some(1), None, &[1])),
        );
        demuxer.finish();
        assert!(demuxer.pop().is_none());
    }
}
