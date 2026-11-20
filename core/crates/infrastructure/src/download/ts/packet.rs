pub const PACKET_SIZE: usize = 188;
pub const SYNC_BYTE: u8 = 0x47;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TsPacket<'a> {
    pub pid: u16,
    pub starts_unit: bool,
    pub payload: &'a [u8],
}

pub fn read_packet(bytes: &[u8]) -> Option<TsPacket<'_>> {
    if bytes.len() != PACKET_SIZE || bytes[0] != SYNC_BYTE {
        return None;
    }
    let starts_unit = bytes[1] & 0x40 != 0;
    let pid = (u16::from(bytes[1] & 0x1F) << 8) | u16::from(bytes[2]);
    let control = (bytes[3] >> 4) & 0x03;
    let start = match control {
        0b01 => 4,
        0b11 => 5 + usize::from(bytes[4]),
        _ => {
            return Some(TsPacket {
                pid,
                starts_unit,
                payload: &[],
            });
        }
    };
    let payload = bytes.get(start..).unwrap_or(&[]);
    Some(TsPacket {
        pid,
        starts_unit,
        payload,
    })
}

#[cfg(test)]
pub fn build_packet(pid: u16, starts_unit: bool, payload: &[u8]) -> Vec<u8> {
    let mut packet = vec![SYNC_BYTE, (pid >> 8) as u8 & 0x1F, pid as u8, 0x10];
    if starts_unit {
        packet[1] |= 0x40;
    }
    let room = PACKET_SIZE - 4;
    if payload.len() < room {
        packet[3] = 0x30;
        let stuffing = room - payload.len() - 1;
        packet.push(stuffing as u8);
        if stuffing > 0 {
            packet.push(0x00);
            packet.extend(std::iter::repeat_n(0xFF, stuffing - 1));
        }
    }
    packet.extend_from_slice(&payload[..payload.len().min(room)]);
    packet
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_payload_only_packet_gives_its_pid_and_payload() {
        let packet = build_packet(0x101, true, &[7; 184]);
        let read = read_packet(&packet).unwrap();
        assert_eq!(read.pid, 0x101);
        assert!(read.starts_unit);
        assert_eq!(read.payload, &[7; 184][..]);
    }

    #[test]
    fn the_adaptation_field_is_skipped() {
        let packet = build_packet(0x100, false, &[1, 2, 3]);
        let read = read_packet(&packet).unwrap();
        assert!(!read.starts_unit);
        assert_eq!(read.payload, &[1, 2, 3]);
    }

    #[test]
    fn a_wrong_size_or_missing_sync_byte_is_not_a_packet() {
        assert!(read_packet(&[SYNC_BYTE; 10]).is_none());
        let mut packet = build_packet(1, false, &[0; 184]);
        packet[0] = 0;
        assert!(read_packet(&packet).is_none());
    }
}
