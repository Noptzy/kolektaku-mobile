use std::io::{self, Read};

use super::frames::{Frame, FrameReader};

pub struct FrameMerge<R: Read> {
    readers: Vec<FrameReader<R>>,
    heads: Vec<Option<Frame>>,
    started: bool,
}

impl<R: Read> FrameMerge<R> {
    pub fn new(readers: Vec<FrameReader<R>>) -> Self {
        let heads = readers.iter().map(|_| None).collect();
        Self {
            readers,
            heads,
            started: false,
        }
    }

    pub fn readers(&self) -> &[FrameReader<R>] {
        &self.readers
    }

    fn start(&mut self) -> io::Result<()> {
        if self.started {
            return Ok(());
        }
        for (reader, head) in self.readers.iter_mut().zip(self.heads.iter_mut()) {
            *head = reader.next_frame()?;
        }
        self.started = true;
        Ok(())
    }

    pub fn next_frame(&mut self) -> io::Result<Option<Frame>> {
        self.start()?;
        let earliest = self
            .heads
            .iter()
            .enumerate()
            .filter_map(|(index, head)| head.as_ref().map(|frame| (index, frame.decode_ticks)))
            .min_by_key(|(_, ticks)| *ticks)
            .map(|(index, _)| index);
        let Some(index) = earliest else {
            return Ok(None);
        };
        let next = self.readers[index].next_frame()?;
        Ok(std::mem::replace(&mut self.heads[index], next))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::download::codec::build_adts;
    use crate::download::ts::{
        ElementaryStream, STREAM_AAC_ADTS, build_packet, build_pat, build_pes, build_pmt,
    };

    fn audio_file(times: &[u64]) -> Vec<u8> {
        let mut bytes = build_packet(0, true, &build_pat(0x1000));
        let stream = ElementaryStream {
            stream_type: STREAM_AAC_ADTS,
            pid: 0x101,
        };
        bytes.extend(build_packet(0x1000, true, &build_pmt(&[stream])));
        for time in times {
            let unit = build_pes(0xC0, Some(*time), None, &build_adts(&[1; 4]));
            bytes.extend(build_packet(0x101, true, &unit));
        }
        bytes
    }

    #[test]
    fn frames_from_several_files_come_out_by_decode_time() {
        let first = audio_file(&[0, 10_000, 30_000]);
        let second = audio_file(&[5_000, 20_000]);
        let mut merge = FrameMerge::new(vec![
            FrameReader::new(first.as_slice(), true),
            FrameReader::new(second.as_slice(), true),
        ]);
        let mut times = Vec::new();
        while let Some(frame) = merge.next_frame().unwrap() {
            times.push(frame.decode_ticks);
        }
        assert_eq!(times, vec![0, 5_000, 10_000, 20_000, 30_000]);
    }
}
