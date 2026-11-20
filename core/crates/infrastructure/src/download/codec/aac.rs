const SAMPLE_RATES: [u32; 13] = [
    96_000, 88_200, 64_000, 48_000, 44_100, 32_000, 24_000, 22_050, 16_000, 12_000, 11_025, 8_000,
    7_350,
];
pub const SAMPLES_PER_FRAME: u64 = 1024;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AudioConfig {
    pub object_type: u8,
    pub rate_index: u8,
    pub channels: u8,
}

impl AudioConfig {
    pub fn sample_rate(self) -> u32 {
        SAMPLE_RATES
            .get(usize::from(self.rate_index))
            .copied()
            .unwrap_or(48_000)
    }

    pub fn codec_private(self) -> Vec<u8> {
        let packed = (u16::from(self.object_type) << 11)
            | (u16::from(self.rate_index) << 7)
            | (u16::from(self.channels) << 3);
        packed.to_be_bytes().to_vec()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AdtsFrame<'a> {
    pub config: AudioConfig,
    pub data: &'a [u8],
}

fn header_at(bytes: &[u8]) -> Option<(AudioConfig, usize, usize)> {
    let header = bytes.get(..7)?;
    if header[0] != 0xFF || header[1] & 0xF0 != 0xF0 {
        return None;
    }
    let protected = header[1] & 0x01 == 0;
    let config = AudioConfig {
        object_type: (header[2] >> 6) + 1,
        rate_index: (header[2] >> 2) & 0x0F,
        channels: ((header[2] & 0x01) << 2) | (header[3] >> 6),
    };
    let length = (usize::from(header[3] & 0x03) << 11)
        | (usize::from(header[4]) << 3)
        | usize::from(header[5] >> 5);
    let header_length = if protected { 9 } else { 7 };
    (length > header_length).then_some((config, header_length, length))
}

pub fn adts_frames(bytes: &[u8]) -> Vec<AdtsFrame<'_>> {
    let mut frames = Vec::new();
    let mut at = 0;
    while at + 7 <= bytes.len() {
        let Some((config, header_length, length)) = header_at(&bytes[at..]) else {
            at += 1;
            continue;
        };
        let Some(data) = bytes.get(at + header_length..at + length) else {
            break;
        };
        frames.push(AdtsFrame { config, data });
        at += length;
    }
    frames
}

#[cfg(test)]
pub fn build_adts(payload: &[u8]) -> Vec<u8> {
    let length = payload.len() + 7;
    let mut frame = vec![
        0xFF,
        0xF1,
        (1 << 6) | (3 << 2),
        (2 << 6) | ((length >> 11) as u8 & 0x03),
        (length >> 3) as u8,
        ((length as u8 & 0x07) << 5) | 0x1F,
        0xFC,
    ];
    frame.extend_from_slice(payload);
    frame
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn frames_lose_their_header_and_keep_the_stream_settings() {
        let mut bytes = build_adts(&[1, 2, 3]);
        bytes.extend(build_adts(&[4, 5]));
        let frames = adts_frames(&bytes);
        assert_eq!(frames.len(), 2);
        assert_eq!(frames[0].data, &[1, 2, 3]);
        assert_eq!(frames[1].data, &[4, 5]);
        let config = frames[0].config;
        assert_eq!((config.object_type, config.channels), (2, 2));
        assert_eq!(config.sample_rate(), 48_000);
    }

    #[test]
    fn the_codec_record_packs_type_rate_and_channels() {
        let config = AudioConfig {
            object_type: 2,
            rate_index: 3,
            channels: 2,
        };
        assert_eq!(config.codec_private(), vec![0x11, 0x90]);
    }

    #[test]
    fn junk_is_skipped_and_a_cut_frame_is_dropped() {
        let mut bytes = vec![0x00, 0x12];
        bytes.extend(build_adts(&[9; 4]));
        let mut cut = build_adts(&[7; 10]);
        cut.truncate(12);
        bytes.extend(cut);
        let frames = adts_frames(&bytes);
        assert_eq!(frames.len(), 1);
        assert_eq!(frames[0].data, &[9; 4]);
    }
}
