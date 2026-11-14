use domain::error::SourceError;
use domain::stream::{SkipKind, StreamKind, StreamSet, SubtitleVariant};

use super::payload::parse_stream_payload;
use crate::fixtures;

fn sample() -> StreamSet {
    parse_stream_payload(&fixtures::hianime("payload.json")).unwrap()
}

#[test]
fn the_master_playlist_is_the_only_source_and_is_adaptive() {
    let set = sample();
    assert_eq!(set.sources.len(), 1);
    let source = set.default_source();
    assert!(source.url.ends_with("/master.m3u8"));
    assert_eq!(source.kind, StreamKind::Hls);
    assert_eq!(source.quality, 0);
    assert_eq!(source.label, "Otomatis");
}

#[test]
fn requests_carry_the_player_page_as_referer_and_origin() {
    let set = sample();
    assert_eq!(
        set.headers,
        vec![
            ("referer".to_string(), "https://zokoanime.video/".to_string()),
            ("origin".to_string(), "https://zokoanime.video".to_string()),
        ]
    );
    assert!(set.poster_url.as_deref().is_some_and(|url| url.ends_with("thumb.jpg")));
}

#[test]
fn only_caption_tracks_become_subtitles_with_languages_and_variants() {
    let set = sample();
    let labels: Vec<&str> = set.subtitles.iter().map(|track| track.label.as_str()).collect();
    assert_eq!(
        labels,
        ["English", "English - Forced", "Indonesian", "Hindi - Latin | Forced"]
    );
    assert!(set.subtitles[0].is_default);
    assert_eq!(set.subtitles[2].language.as_deref(), Some("id"));
    assert_eq!(set.subtitles[1].variant, SubtitleVariant::Forced);
    assert!(set.subtitles.iter().all(|track| track.url.starts_with("https://")));
}

#[test]
fn skip_marks_become_millisecond_ranges() {
    let set = sample();
    assert_eq!(set.skips.len(), 2);
    assert_eq!(
        (set.skips[0].kind, set.skips[0].start_ms, set.skips[0].end_ms),
        (SkipKind::Intro, 72_000, 158_000)
    );
    assert_eq!(set.skips[1].kind, SkipKind::Outro);
}

#[test]
fn a_payload_without_marks_or_tracks_still_plays() {
    let set = parse_stream_payload(
        r#"{"origin":"https://p.test","file":"https://h.test/a.m3u8","tracks":[],"marks":[]}"#,
    )
    .unwrap();
    assert!(set.subtitles.is_empty() && set.skips.is_empty());
    assert_eq!(set.poster_url, None);
}

#[test]
fn broken_marks_and_unsafe_tracks_are_dropped_one_by_one() {
    let set = parse_stream_payload(
        r#"{"origin":"https://p.test","file":"https://h.test/a.m3u8","tracks":[
            {"file":"http://h.test/x.vtt","label":"English","kind":"captions"},
            {"file":"https://h.test/y.vtt","label":"","kind":"captions"},
            {"file":"https://h.test/z.vtt","label":"Indonesian","kind":"captions"}],
          "marks":[{"kind":"intro","start":10,"end":5},{"kind":"credits","start":1,"end":2},
            {"kind":"outro","start":100,"end":120},{"kind":"intro","start":null,"end":3}]}"#,
    )
    .unwrap();
    assert_eq!(set.subtitles.len(), 1);
    assert_eq!(set.subtitles[0].label, "Indonesian");
    assert_eq!(set.skips.len(), 1);
    assert_eq!(set.skips[0].kind, SkipKind::Outro);
}

#[test]
fn without_a_secure_origin_no_headers_are_invented() {
    let set = parse_stream_payload(
        r#"{"origin":"http://p.test","file":"https://h.test/a.m3u8"}"#,
    )
    .unwrap();
    assert!(set.headers.is_empty());
}

#[test]
fn a_missing_or_insecure_stream_is_a_markup_change() {
    for payload in [
        r#"{"origin":"https://p.test"}"#,
        r#"{"file":"http://h.test/a.m3u8"}"#,
        r#"{"file":"javascript:alert(1)"}"#,
        r#"{"file":""}"#,
        "not json",
        "",
    ] {
        assert!(
            matches!(parse_stream_payload(payload), Err(SourceError::MarkupChanged(_))),
            "{payload:?}"
        );
    }
}

#[test]
fn a_plain_file_is_not_called_adaptive() {
    let set = parse_stream_payload(r#"{"file":"https://h.test/a.mp4"}"#).unwrap();
    assert_eq!(set.default_source().kind, StreamKind::Mp4);
}
