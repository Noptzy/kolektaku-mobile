const NAL_IDR: u8 = 5;
const NAL_SPS: u8 = 7;
const NAL_PPS: u8 = 8;
const NAL_DELIMITER: u8 = 9;

pub fn nal_units(annex_b: &[u8]) -> Vec<&[u8]> {
    let mut starts = Vec::new();
    let mut at = 0;
    while at + 3 <= annex_b.len() {
        if annex_b[at] == 0 && annex_b[at + 1] == 0 && annex_b[at + 2] == 1 {
            starts.push(at + 3);
            at += 3;
        } else {
            at += 1;
        }
    }
    let mut units = Vec::with_capacity(starts.len());
    for (index, &start) in starts.iter().enumerate() {
        let mut end = starts.get(index + 1).map_or(annex_b.len(), |next| next - 3);
        while end > start && annex_b[end - 1] == 0 {
            end -= 1;
        }
        if end > start {
            units.push(&annex_b[start..end]);
        }
    }
    units
}

fn nal_type(unit: &[u8]) -> u8 {
    unit[0] & 0x1F
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ParameterSets {
    pub sps: Option<Vec<u8>>,
    pub pps: Option<Vec<u8>>,
}

impl ParameterSets {
    pub fn is_complete(&self) -> bool {
        self.sps.is_some() && self.pps.is_some()
    }

    pub fn codec_private(&self) -> Option<Vec<u8>> {
        let sps = self.sps.as_ref().filter(|sps| sps.len() >= 4)?;
        let pps = self.pps.as_ref()?;
        let mut record = vec![1, sps[1], sps[2], sps[3], 0xFF, 0xE1];
        record.extend((sps.len() as u16).to_be_bytes());
        record.extend(sps);
        record.push(1);
        record.extend((pps.len() as u16).to_be_bytes());
        record.extend(pps);
        Some(record)
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AvcFrame {
    pub data: Vec<u8>,
    pub keyframe: bool,
}

pub fn to_avc_frame(annex_b: &[u8], parameters: &mut ParameterSets) -> Option<AvcFrame> {
    let mut data = Vec::with_capacity(annex_b.len() + 16);
    let mut keyframe = false;
    for unit in nal_units(annex_b) {
        match nal_type(unit) {
            NAL_SPS => {
                parameters.sps.get_or_insert_with(|| unit.to_vec());
            }
            NAL_PPS => {
                parameters.pps.get_or_insert_with(|| unit.to_vec());
            }
            NAL_DELIMITER => {}
            kind => {
                keyframe |= kind == NAL_IDR;
                data.extend((unit.len() as u32).to_be_bytes());
                data.extend_from_slice(unit);
            }
        }
    }
    (!data.is_empty()).then_some(AvcFrame { data, keyframe })
}

#[cfg(test)]
mod tests {
    use super::*;

    const SPS: [u8; 5] = [0x67, 0x64, 0x00, 0x1F, 0xAC];
    const PPS: [u8; 3] = [0x68, 0xEE, 0x3C];

    fn access_unit(slice_type: u8) -> Vec<u8> {
        let mut bytes = vec![0, 0, 0, 1, 0x09, 0xF0];
        bytes.extend([0, 0, 0, 1]);
        bytes.extend(SPS);
        bytes.extend([0, 0, 1]);
        bytes.extend(PPS);
        bytes.extend([0, 0, 1, slice_type, 0xAA, 0xBB, 0x00]);
        bytes
    }

    #[test]
    fn units_are_split_on_both_start_code_lengths_without_trailing_zeros() {
        let bytes = access_unit(0x65);
        let units = nal_units(&bytes);
        assert_eq!(units.len(), 4);
        assert_eq!(units[1], SPS);
        assert_eq!(units[3], [0x65, 0xAA, 0xBB]);
    }

    #[test]
    fn an_idr_frame_becomes_a_length_prefixed_keyframe_and_keeps_the_parameters() {
        let mut parameters = ParameterSets::default();
        let frame = to_avc_frame(&access_unit(0x65), &mut parameters).unwrap();
        assert!(frame.keyframe);
        assert_eq!(frame.data, vec![0, 0, 0, 3, 0x65, 0xAA, 0xBB]);
        assert!(parameters.is_complete());
        let record = parameters.codec_private().unwrap();
        assert_eq!(&record[..6], &[1, 0x64, 0x00, 0x1F, 0xFF, 0xE1]);
        assert_eq!(&record[6..8], &[0, 5]);
        assert_eq!(&record[13..16], &[1, 0, 3]);
    }

    #[test]
    fn a_plain_slice_is_not_a_keyframe() {
        let mut parameters = ParameterSets::default();
        let frame = to_avc_frame(&access_unit(0x41), &mut parameters).unwrap();
        assert!(!frame.keyframe);
    }

    #[test]
    fn a_unit_with_only_parameters_gives_no_frame() {
        let mut parameters = ParameterSets::default();
        let mut bytes = vec![0, 0, 1];
        bytes.extend(SPS);
        assert!(to_avc_frame(&bytes, &mut parameters).is_none());
        assert!(parameters.codec_private().is_none());
    }
}
