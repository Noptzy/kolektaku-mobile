use std::io::Cursor;

use super::ebml::id_bytes;
use super::ids;
use super::tracks::{TrackKind, TrackSpec};
use super::writer::MkvWriter;

fn tracks() -> Vec<TrackSpec> {
    vec![
        TrackSpec {
            number: 1,
            kind: TrackKind::Video {
                width: 640,
                height: 360,
            },
            codec_id: "V_MPEG4/ISO/AVC",
            codec_private: Some(vec![1, 0x64, 0, 0x1F, 0xFF, 0xE1, 0, 0, 1, 0, 0]),
            language: None,
            name: None,
            default: true,
        },
        TrackSpec {
            number: 2,
            kind: TrackKind::Subtitle,
            codec_id: "S_TEXT/UTF8",
            codec_private: None,
            language: Some("id".into()),
            name: Some("Indonesia".into()),
            default: true,
        },
    ]
}

fn find(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack
        .windows(needle.len())
        .position(|window| window == needle)
}

fn written() -> Vec<u8> {
    let mut writer = MkvWriter::start(Cursor::new(Vec::new()), &tracks()).unwrap();
    writer.write_frame(1, 0, true, &[0xAA]).unwrap();
    writer.write_text(2, 100, 900, "Halo").unwrap();
    writer.write_frame(1, 40, false, &[0xBB]).unwrap();
    writer.write_frame(1, 2_000, true, &[0xCC]).unwrap();
    writer.finish(2_040.0).unwrap().into_inner()
}

#[test]
fn the_file_starts_with_the_matroska_header_and_a_sized_segment() {
    let bytes = written();
    assert_eq!(&bytes[..4], &id_bytes(ids::EBML)[..]);
    assert!(find(&bytes, b"matroska").is_some());
    let segment = find(&bytes, &id_bytes(ids::SEGMENT)).unwrap();
    let size_field = &bytes[segment + 4..segment + 12];
    assert_eq!(size_field[0], 0x01);
    let mut size_bytes = [0u8; 8];
    size_bytes[1..].copy_from_slice(&size_field[1..]);
    let size = u64::from_be_bytes(size_bytes);
    assert_eq!(size as usize, bytes.len() - (segment + 12));
}

#[test]
fn the_duration_is_filled_in_at_the_end() {
    let bytes = written();
    let at = find(&bytes, &[0x44, 0x89, 0x88]).unwrap();
    let mut value = [0u8; 8];
    value.copy_from_slice(&bytes[at + 3..at + 11]);
    assert_eq!(f64::from_be_bytes(value), 2_040.0);
}

#[test]
fn keyframes_open_clusters_that_the_cues_point_at() {
    let bytes = written();
    let clusters = bytes
        .windows(4)
        .filter(|window| *window == id_bytes(ids::CLUSTER).as_slice())
        .count();
    assert_eq!(clusters, 2);
    let cues = find(&bytes, &id_bytes(ids::CUES)).unwrap();
    let points = bytes[cues..]
        .windows(1)
        .filter(|window| window[0] == 0xBB)
        .count();
    assert!(points >= 2);
}

#[test]
fn the_seek_head_points_at_info_tracks_and_cues() {
    let bytes = written();
    let head = find(&bytes, &id_bytes(ids::SEEK_HEAD)).unwrap();
    let segment = find(&bytes, &id_bytes(ids::SEGMENT)).unwrap();
    assert_eq!(head, segment + 12);
    for id in [ids::INFO, ids::TRACKS, ids::CUES] {
        let mut entry = vec![0x53, 0xAB, 0x84];
        entry.extend(id_bytes(id));
        assert!(find(&bytes[head..head + 96], &entry).is_some(), "{id:x}");
    }
}

#[test]
fn subtitles_are_stored_as_text_blocks() {
    let bytes = written();
    assert!(find(&bytes, b"Halo").is_some());
    assert!(find(&bytes, b"S_TEXT/UTF8").is_some());
}
