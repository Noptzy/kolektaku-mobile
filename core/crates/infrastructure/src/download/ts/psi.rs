#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ElementaryStream {
    pub stream_type: u8,
    pub pid: u16,
}

fn section(payload: &[u8], table_id: u8) -> Option<&[u8]> {
    let pointer = usize::from(*payload.first()?);
    let table = payload.get(1 + pointer..)?;
    if *table.first()? != table_id {
        return None;
    }
    let length = (usize::from(table.get(1)? & 0x0F) << 8) | usize::from(*table.get(2)?);
    let end = (3 + length).checked_sub(4)?;
    table.get(3..end.min(table.len()))
}

fn pid_at(bytes: &[u8], at: usize) -> Option<u16> {
    Some((u16::from(bytes.get(at)? & 0x1F) << 8) | u16::from(*bytes.get(at + 1)?))
}

pub fn program_map_pid(payload: &[u8]) -> Option<u16> {
    let body = section(payload, 0x00)?;
    body.get(5..)?
        .as_chunks::<4>()
        .0
        .iter()
        .find(|entry| u16::from_be_bytes([entry[0], entry[1]]) != 0)
        .and_then(|entry| pid_at(entry, 2))
}

pub fn elementary_streams(payload: &[u8]) -> Vec<ElementaryStream> {
    let Some(body) = section(payload, 0x02) else {
        return Vec::new();
    };
    let Some(info_length) = body
        .get(7..9)
        .map(|bytes| (usize::from(bytes[0] & 0x0F) << 8) | usize::from(bytes[1]))
    else {
        return Vec::new();
    };
    let mut streams = Vec::new();
    let mut at = 9 + info_length;
    while at + 5 <= body.len() {
        let stream_type = body[at];
        let Some(pid) = pid_at(body, at + 1) else {
            break;
        };
        let es_length = (usize::from(body[at + 3] & 0x0F) << 8) | usize::from(body[at + 4]);
        streams.push(ElementaryStream { stream_type, pid });
        at += 5 + es_length;
    }
    streams
}

#[cfg(test)]
pub fn build_pat(pmt_pid: u16) -> Vec<u8> {
    let mut table = vec![0x00, 0xB0, 13, 0x00, 0x01, 0xC1, 0x00, 0x00];
    table.extend([0x00, 0x01, 0xE0 | (pmt_pid >> 8) as u8, pmt_pid as u8]);
    table.extend([0; 4]);
    let mut payload = vec![0x00];
    payload.extend(table);
    payload
}

#[cfg(test)]
pub fn build_pmt(streams: &[ElementaryStream]) -> Vec<u8> {
    let mut body = vec![0x00, 0x01, 0xC1, 0x00, 0x00, 0xE1, 0x00, 0xF0, 0x00];
    for stream in streams {
        body.push(stream.stream_type);
        body.extend([0xE0 | (stream.pid >> 8) as u8, stream.pid as u8, 0xF0, 0x00]);
    }
    let length = body.len() + 4;
    let mut payload = vec![0x00, 0x02, 0xB0 | (length >> 8) as u8, length as u8];
    payload.extend(body);
    payload.extend([0; 4]);
    payload
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_program_table_points_at_the_program_map() {
        assert_eq!(program_map_pid(&build_pat(0x1000)), Some(0x1000));
        assert_eq!(program_map_pid(&[0x00, 0x42]), None);
    }

    #[test]
    fn the_program_map_lists_each_stream_type_and_pid() {
        let streams = [
            ElementaryStream {
                stream_type: 0x1B,
                pid: 0x100,
            },
            ElementaryStream {
                stream_type: 0x0F,
                pid: 0x101,
            },
        ];
        assert_eq!(elementary_streams(&build_pmt(&streams)), streams.to_vec());
    }

    #[test]
    fn a_table_of_the_wrong_kind_lists_nothing() {
        assert!(elementary_streams(&build_pat(0x1000)).is_empty());
        assert!(elementary_streams(&[]).is_empty());
    }
}
