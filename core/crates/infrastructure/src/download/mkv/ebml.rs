pub fn id_bytes(id: u32) -> Vec<u8> {
    let bytes = id.to_be_bytes();
    let first = bytes.iter().position(|byte| *byte != 0).unwrap_or(3);
    bytes[first..].to_vec()
}

pub fn fixed_size(size: u64, length: usize) -> Vec<u8> {
    let marker = 1u64 << (7 * length);
    let value = marker | size;
    value.to_be_bytes()[8 - length..].to_vec()
}

pub fn size_bytes(size: u64) -> Vec<u8> {
    let length = (1..=8)
        .find(|length| size < (1u64 << (7 * length)) - 1)
        .unwrap_or(8);
    fixed_size(size, length)
}

pub fn element(id: u32, body: &[u8]) -> Vec<u8> {
    let mut out = id_bytes(id);
    out.extend(size_bytes(body.len() as u64));
    out.extend_from_slice(body);
    out
}

pub fn uint_element(id: u32, value: u64) -> Vec<u8> {
    let bytes = value.to_be_bytes();
    let first = bytes.iter().position(|byte| *byte != 0).unwrap_or(7);
    element(id, &bytes[first..])
}

pub fn fixed_uint_element(id: u32, value: u64) -> Vec<u8> {
    element(id, &value.to_be_bytes())
}

pub fn float_element(id: u32, value: f64) -> Vec<u8> {
    element(id, &value.to_be_bytes())
}

pub fn text_element(id: u32, text: &str) -> Vec<u8> {
    element(id, text.as_bytes())
}

pub fn void(total: usize) -> Vec<u8> {
    let mut out = vec![0xEC];
    if total < 2 + 127 {
        out.extend(fixed_size(total.saturating_sub(2) as u64, 1));
    } else {
        out.extend(fixed_size((total - 9) as u64, 8));
    }
    out.resize(total, 0);
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn ids_keep_their_marker_bits_and_drop_leading_zeros() {
        assert_eq!(id_bytes(0xA3), vec![0xA3]);
        assert_eq!(id_bytes(0x4286), vec![0x42, 0x86]);
        assert_eq!(id_bytes(0x1A45_DFA3), vec![0x1A, 0x45, 0xDF, 0xA3]);
    }

    #[test]
    fn sizes_use_the_shortest_form_and_avoid_the_reserved_all_ones() {
        assert_eq!(size_bytes(0), vec![0x80]);
        assert_eq!(size_bytes(126), vec![0xFE]);
        assert_eq!(size_bytes(127), vec![0x40, 0x7F]);
        assert_eq!(fixed_size(5, 8), vec![0x01, 0, 0, 0, 0, 0, 0, 5]);
    }

    #[test]
    fn numbers_and_text_are_wrapped_in_their_element() {
        assert_eq!(uint_element(0xD7, 1), vec![0xD7, 0x81, 0x01]);
        assert_eq!(uint_element(0xD7, 0), vec![0xD7, 0x81, 0x00]);
        assert_eq!(
            uint_element(0x2A_D7B1, 1_000_000),
            vec![0x2A, 0xD7, 0xB1, 0x83, 0x0F, 0x42, 0x40]
        );
        assert_eq!(text_element(0x86, "A"), vec![0x86, 0x81, b'A']);
        assert_eq!(float_element(0x4489, 1.0).len(), 2 + 1 + 8);
        assert_eq!(fixed_uint_element(0x53AC, 3).len(), 2 + 1 + 8);
    }

    #[test]
    fn a_void_fills_exactly_the_space_given() {
        for total in [2, 50, 128, 129, 130, 400] {
            let filler = void(total);
            assert_eq!(filler.len(), total, "{total}");
            assert_eq!(filler[0], 0xEC);
        }
    }
}
