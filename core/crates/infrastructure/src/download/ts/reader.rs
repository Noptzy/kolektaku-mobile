use std::io::{self, Read};

use super::demux::{ElementaryUnit, TsDemuxer};
use super::packet::{PACKET_SIZE, SYNC_BYTE};

const READ_CHUNK: usize = PACKET_SIZE * 512;

pub struct TsReader<R: Read> {
    input: R,
    buffer: Vec<u8>,
    demuxer: TsDemuxer,
    ended: bool,
}

impl<R: Read> TsReader<R> {
    pub fn new(input: R) -> Self {
        Self {
            input,
            buffer: Vec::with_capacity(READ_CHUNK * 2),
            demuxer: TsDemuxer::default(),
            ended: false,
        }
    }

    pub fn next_unit(&mut self) -> io::Result<Option<ElementaryUnit>> {
        loop {
            if let Some(unit) = self.demuxer.pop() {
                return Ok(Some(unit));
            }
            if self.ended {
                return Ok(None);
            }
            self.fill()?;
        }
    }

    fn fill(&mut self) -> io::Result<()> {
        let mut chunk = vec![0u8; READ_CHUNK];
        let read = self.input.read(&mut chunk)?;
        if read == 0 {
            self.ended = true;
            self.demuxer.finish();
            return Ok(());
        }
        self.buffer.extend_from_slice(&chunk[..read]);
        self.drain_packets();
        Ok(())
    }

    fn drain_packets(&mut self) {
        let mut at = 0;
        while at + PACKET_SIZE <= self.buffer.len() {
            if self.buffer[at] != SYNC_BYTE {
                at += 1;
                continue;
            }
            self.demuxer.push(&self.buffer[at..at + PACKET_SIZE]);
            at += PACKET_SIZE;
        }
        self.buffer.drain(..at);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::download::ts::demux::STREAM_H264;
    use crate::download::ts::packet::build_packet;
    use crate::download::ts::pes::build_pes;
    use crate::download::ts::psi::{ElementaryStream, build_pat, build_pmt};

    #[test]
    fn units_are_read_across_chunks_and_junk_between_packets_is_skipped() {
        let mut bytes = build_packet(0, true, &build_pat(0x1000));
        bytes.extend([0x00, 0x11]);
        let stream = ElementaryStream {
            stream_type: STREAM_H264,
            pid: 0x100,
        };
        bytes.extend(build_packet(0x1000, true, &build_pmt(&[stream])));
        for index in 0..600u64 {
            bytes.extend(build_packet(
                0x100,
                true,
                &build_pes(0xE0, Some(index), None, &[1]),
            ));
        }
        let mut reader = TsReader::new(bytes.as_slice());
        let mut count = 0;
        while let Some(unit) = reader.next_unit().unwrap() {
            assert_eq!(unit.pts, Some(count));
            count += 1;
        }
        assert_eq!(count, 600);
    }
}
