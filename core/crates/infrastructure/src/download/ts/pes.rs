#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PesUnit<'a> {
    pub pts: Option<u64>,
    pub dts: Option<u64>,
    pub payload: &'a [u8],
}

fn timestamp(bytes: &[u8]) -> Option<u64> {
    let bytes = bytes.get(..5)?;
    Some(
        (u64::from(bytes[0] >> 1 & 0x07) << 30)
            | (u64::from(bytes[1]) << 22)
            | (u64::from(bytes[2] >> 1) << 15)
            | (u64::from(bytes[3]) << 7)
            | u64::from(bytes[4] >> 1),
    )
}

pub fn parse_pes(unit: &[u8]) -> Option<PesUnit<'_>> {
    if unit.get(..3)? != [0x00, 0x00, 0x01] {
        return None;
    }
    let flags = *unit.get(7)?;
    let header_length = usize::from(*unit.get(8)?);
    let optional = unit.get(9..9 + header_length)?;
    let pts = if flags & 0x80 != 0 {
        timestamp(optional)
    } else {
        None
    };
    let dts = if flags & 0x40 != 0 {
        optional.get(5..).and_then(timestamp)
    } else {
        None
    };
    Some(PesUnit {
        pts,
        dts,
        payload: &unit[9 + header_length..],
    })
}

#[cfg(test)]
fn encode_timestamp(marker: u8, value: u64) -> [u8; 5] {
    [
        marker << 4 | ((value >> 29) as u8 & 0x0E) | 1,
        (value >> 22) as u8,
        ((value >> 14) as u8 & 0xFE) | 1,
        (value >> 7) as u8,
        ((value << 1) as u8) | 1,
    ]
}

#[cfg(test)]
pub fn build_pes(stream_id: u8, pts: Option<u64>, dts: Option<u64>, payload: &[u8]) -> Vec<u8> {
    let mut optional = Vec::new();
    let mut flags = 0u8;
    if let Some(value) = pts {
        flags |= 0x80;
        optional.extend(encode_timestamp(if dts.is_some() { 3 } else { 2 }, value));
    }
    if let Some(value) = dts {
        flags |= 0x40;
        optional.extend(encode_timestamp(1, value));
    }
    let mut unit = vec![
        0x00,
        0x00,
        0x01,
        stream_id,
        0x00,
        0x00,
        0x80,
        flags,
        optional.len() as u8,
    ];
    unit.extend(optional);
    unit.extend_from_slice(payload);
    unit
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn presentation_and_decode_times_are_read_back() {
        let unit = build_pes(0xE0, Some(900_000), Some(897_000), &[9, 9]);
        let parsed = parse_pes(&unit).unwrap();
        assert_eq!(parsed.pts, Some(900_000));
        assert_eq!(parsed.dts, Some(897_000));
        assert_eq!(parsed.payload, &[9, 9]);
    }

    #[test]
    fn a_large_time_near_the_33_bit_limit_survives() {
        let big = (1u64 << 33) - 5;
        let parsed_unit = build_pes(0xC0, Some(big), None, &[]);
        let parsed = parse_pes(&parsed_unit).unwrap();
        assert_eq!(parsed.pts, Some(big));
        assert_eq!(parsed.dts, None);
    }

    #[test]
    fn bytes_without_a_start_code_are_not_a_unit() {
        assert!(parse_pes(&[0, 0, 2, 0xE0]).is_none());
        assert!(parse_pes(&[0, 0, 1]).is_none());
    }
}
