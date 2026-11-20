use super::ebml::{element, float_element, text_element, uint_element};
use super::ids;

#[derive(Debug, Clone, PartialEq)]
pub enum TrackKind {
    Video { width: u32, height: u32 },
    Audio { sample_rate: u32, channels: u8 },
    Subtitle,
}

#[derive(Debug, Clone, PartialEq)]
pub struct TrackSpec {
    pub number: u64,
    pub kind: TrackKind,
    pub codec_id: &'static str,
    pub codec_private: Option<Vec<u8>>,
    pub language: Option<String>,
    pub name: Option<String>,
    pub default: bool,
}

const LEGACY_CODES: [(&str, &str); 18] = [
    ("id", "ind"),
    ("en", "eng"),
    ("ja", "jpn"),
    ("ms", "may"),
    ("zh", "chi"),
    ("ko", "kor"),
    ("ar", "ara"),
    ("th", "tha"),
    ("vi", "vie"),
    ("fil", "fil"),
    ("es", "spa"),
    ("pt", "por"),
    ("fr", "fre"),
    ("de", "ger"),
    ("ru", "rus"),
    ("hi", "hin"),
    ("tr", "tur"),
    ("it", "ita"),
];

pub fn legacy_language(code: Option<&str>) -> &'static str {
    let primary = code
        .unwrap_or_default()
        .split(['-', '_'])
        .next()
        .unwrap_or_default()
        .to_ascii_lowercase();
    LEGACY_CODES
        .iter()
        .find(|(short, _)| *short == primary)
        .map_or("und", |(_, long)| long)
}

fn type_code(kind: &TrackKind) -> u64 {
    match kind {
        TrackKind::Video { .. } => 1,
        TrackKind::Audio { .. } => 2,
        TrackKind::Subtitle => 0x11,
    }
}

fn kind_settings(kind: &TrackKind) -> Vec<u8> {
    match kind {
        TrackKind::Video { width, height } => {
            let mut body = uint_element(ids::PIXEL_WIDTH, u64::from(*width));
            body.extend(uint_element(ids::PIXEL_HEIGHT, u64::from(*height)));
            element(ids::VIDEO, &body)
        }
        TrackKind::Audio {
            sample_rate,
            channels,
        } => {
            let mut body = float_element(ids::SAMPLING_FREQUENCY, f64::from(*sample_rate));
            body.extend(uint_element(ids::CHANNELS, u64::from(*channels)));
            element(ids::AUDIO, &body)
        }
        TrackKind::Subtitle => Vec::new(),
    }
}

pub fn track_entry(track: &TrackSpec) -> Vec<u8> {
    let mut body = uint_element(ids::TRACK_NUMBER, track.number);
    body.extend(uint_element(ids::TRACK_UID, 0x4B4F_4C00 + track.number));
    body.extend(uint_element(ids::TRACK_TYPE, type_code(&track.kind)));
    body.extend(uint_element(ids::FLAG_DEFAULT, u64::from(track.default)));
    body.extend(uint_element(ids::FLAG_LACING, 0));
    body.extend(text_element(
        ids::LANGUAGE,
        legacy_language(track.language.as_deref()),
    ));
    if let Some(code) = track.language.as_deref() {
        body.extend(text_element(ids::LANGUAGE_BCP47, code));
    }
    if let Some(name) = track.name.as_deref() {
        body.extend(text_element(ids::NAME, name));
    }
    body.extend(text_element(ids::CODEC_ID, track.codec_id));
    if let Some(private) = track.codec_private.as_deref() {
        body.extend(element(ids::CODEC_PRIVATE, private));
    }
    body.extend(kind_settings(&track.kind));
    element(ids::TRACK_ENTRY, &body)
}

pub fn tracks_element(tracks: &[TrackSpec]) -> Vec<u8> {
    let body: Vec<u8> = tracks.iter().flat_map(track_entry).collect();
    element(ids::TRACKS, &body)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn subtitle() -> TrackSpec {
        TrackSpec {
            number: 3,
            kind: TrackKind::Subtitle,
            codec_id: "S_TEXT/UTF8",
            codec_private: None,
            language: Some("id".into()),
            name: Some("Indonesia".into()),
            default: true,
        }
    }

    fn contains(haystack: &[u8], needle: &[u8]) -> bool {
        haystack
            .windows(needle.len())
            .any(|window| window == needle)
    }

    #[test]
    fn short_language_codes_become_the_three_letter_form() {
        assert_eq!(legacy_language(Some("id")), "ind");
        assert_eq!(legacy_language(Some("en-US")), "eng");
        assert_eq!(legacy_language(Some("xx")), "und");
        assert_eq!(legacy_language(None), "und");
    }

    #[test]
    fn a_subtitle_entry_names_its_codec_language_and_title() {
        let entry = track_entry(&subtitle());
        assert_eq!(entry[0], 0xAE);
        assert!(contains(&entry, b"S_TEXT/UTF8"));
        assert!(contains(&entry, b"ind"));
        assert!(contains(&entry, b"Indonesia"));
        assert!(contains(&entry, &[0x83, 0x81, 0x11]));
    }

    #[test]
    fn video_and_audio_entries_carry_their_picture_and_sound_settings() {
        let video = TrackSpec {
            number: 1,
            kind: TrackKind::Video {
                width: 1280,
                height: 720,
            },
            codec_id: "V_MPEG4/ISO/AVC",
            codec_private: Some(vec![1, 2, 3]),
            language: None,
            name: None,
            default: true,
        };
        let entry = track_entry(&video);
        assert!(contains(&entry, &[0xB0, 0x82, 0x05, 0x00]));
        assert!(contains(&entry, &[0xBA, 0x82, 0x02, 0xD0]));
        assert!(contains(&entry, &[0x63, 0xA2, 0x83, 1, 2, 3]));
        let tracks = tracks_element(&[video, subtitle()]);
        assert_eq!(&tracks[..4], &[0x16, 0x54, 0xAE, 0x6B]);
    }
}
