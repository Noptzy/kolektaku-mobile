use super::codec::build_adts;
use super::ts::{
    ElementaryStream, STREAM_AAC_ADTS, STREAM_H264, build_packet, build_pat, build_pes, build_pmt,
};

fn ts_file(streams: &[ElementaryStream], units: Vec<(u16, Vec<u8>)>) -> Vec<u8> {
    let mut bytes = build_packet(0, true, &build_pat(0x1000));
    bytes.extend(build_packet(0x1000, true, &build_pmt(streams)));
    for (pid, unit) in units {
        for (index, chunk) in unit.chunks(184).enumerate() {
            bytes.extend(build_packet(pid, index == 0, chunk));
        }
    }
    bytes
}

fn video_unit(index: u64) -> Vec<u8> {
    let mut nal = vec![0, 0, 1, 0x67, 0x64, 0, 0x1F, 0xAC, 0, 0, 1, 0x68, 0xEE];
    nal.extend([
        0,
        0,
        1,
        if index.is_multiple_of(25) { 0x65 } else { 0x41 },
        0x88,
        index as u8,
    ]);
    let time = 90_000 + index * 3_600;
    build_pes(0xE0, Some(time), Some(time), &nal)
}

pub fn video_ts() -> Vec<u8> {
    let stream = ElementaryStream {
        stream_type: STREAM_H264,
        pid: 0x100,
    };
    ts_file(
        &[stream],
        (0..75).map(|index| (0x100, video_unit(index))).collect(),
    )
}

pub fn audio_ts() -> Vec<u8> {
    let stream = ElementaryStream {
        stream_type: STREAM_AAC_ADTS,
        pid: 0x101,
    };
    let units = (0..90u64)
        .map(|index| {
            let unit = build_pes(
                0xC0,
                Some(90_000 + index * 1_920),
                None,
                &build_adts(&[7; 6]),
            );
            (0x101, unit)
        })
        .collect();
    ts_file(&[stream], units)
}
