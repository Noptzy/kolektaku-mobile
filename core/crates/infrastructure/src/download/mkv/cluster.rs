use super::ebml::{element, uint_element};
use super::ids;

const LONGEST_CLUSTER_MS: i64 = 30_000;
const SHORTEST_KEYFRAME_CLUSTER_MS: i64 = 1_000;

pub struct Cluster {
    pub start_ms: i64,
    pub opened_by_keyframe: bool,
    body: Vec<u8>,
}

fn block_header(track: u64, relative: i16, flags: u8) -> Vec<u8> {
    let mut header = vec![0x80 | track as u8];
    header.extend(relative.to_be_bytes());
    header.push(flags);
    header
}

impl Cluster {
    pub fn open(start_ms: i64, opened_by_keyframe: bool) -> Self {
        Self {
            start_ms: start_ms.max(0),
            opened_by_keyframe,
            body: uint_element(ids::TIMESTAMP, start_ms.max(0) as u64),
        }
    }

    pub fn wants_new(&self, time_ms: i64, video_keyframe: bool) -> bool {
        let span = time_ms - self.start_ms;
        span.abs() > LONGEST_CLUSTER_MS || (video_keyframe && span >= SHORTEST_KEYFRAME_CLUSTER_MS)
    }

    fn relative(&self, time_ms: i64) -> i16 {
        (time_ms - self.start_ms).clamp(i64::from(i16::MIN), i64::from(i16::MAX)) as i16
    }

    pub fn add_frame(&mut self, track: u64, time_ms: i64, keyframe: bool, data: &[u8]) {
        let mut block = block_header(
            track,
            self.relative(time_ms),
            if keyframe { 0x80 } else { 0 },
        );
        block.extend_from_slice(data);
        self.body.extend(element(ids::SIMPLE_BLOCK, &block));
    }

    pub fn add_text(&mut self, track: u64, time_ms: i64, duration_ms: u64, text: &str) {
        let mut block = block_header(track, self.relative(time_ms), 0);
        block.extend_from_slice(text.as_bytes());
        let mut group = element(ids::BLOCK, &block);
        group.extend(uint_element(ids::BLOCK_DURATION, duration_ms));
        self.body.extend(element(ids::BLOCK_GROUP, &group));
    }

    pub fn into_bytes(self) -> Vec<u8> {
        element(ids::CLUSTER, &self.body)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_frame_is_stored_with_its_track_relative_time_and_keyframe_flag() {
        let mut cluster = Cluster::open(1_000, true);
        cluster.add_frame(1, 1_040, true, &[9, 9]);
        let bytes = cluster.into_bytes();
        assert_eq!(&bytes[..4], &[0x1F, 0x43, 0xB6, 0x75]);
        let block = [0xA3, 0x86, 0x81, 0x00, 0x28, 0x80, 9, 9];
        assert!(bytes.windows(block.len()).any(|window| window == block));
    }

    #[test]
    fn text_goes_in_a_group_with_its_duration() {
        let mut cluster = Cluster::open(0, false);
        cluster.add_text(3, 500, 2_000, "Hai");
        let bytes = cluster.into_bytes();
        assert!(bytes.windows(3).any(|window| window == b"Hai"));
        assert!(
            bytes
                .windows(4)
                .any(|window| window == [0x9B, 0x82, 0x07, 0xD0])
        );
    }

    #[test]
    fn a_new_cluster_starts_at_a_later_keyframe_or_when_it_grows_too_long() {
        let cluster = Cluster::open(0, true);
        assert!(!cluster.wants_new(500, true));
        assert!(cluster.wants_new(1_000, true));
        assert!(!cluster.wants_new(20_000, false));
        assert!(cluster.wants_new(30_001, false));
    }

    #[test]
    fn a_time_before_the_cluster_start_is_kept_as_a_negative_offset() {
        let mut cluster = Cluster::open(1_000, true);
        cluster.add_frame(2, 960, false, &[1]);
        let bytes = cluster.into_bytes();
        let offset = (-40i16).to_be_bytes();
        let block = [0x82, offset[0], offset[1], 0x00, 1];
        assert!(bytes.windows(block.len()).any(|window| window == block));
    }
}
