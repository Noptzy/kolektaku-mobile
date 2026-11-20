use domain::error::SourceError;
use url::Url;

use super::attributes::{attribute, parse_attributes};

#[derive(Debug, Clone, PartialEq)]
pub struct Segment {
    pub url: String,
    pub duration: f64,
}

#[derive(Debug, Clone, PartialEq, Default)]
pub struct MediaPlaylist {
    pub segments: Vec<Segment>,
}

impl MediaPlaylist {
    pub fn duration(&self) -> f64 {
        self.segments.iter().map(|segment| segment.duration).sum()
    }
}

const SEGMENT_INFO: &str = "#EXTINF:";
const KEY: &str = "#EXT-X-KEY:";
const MAP: &str = "#EXT-X-MAP:";

fn unsupported(detail: &str) -> SourceError {
    SourceError::Unsupported(format!("this video cannot be saved yet: {detail}"))
}

fn refuse_encryption(rest: &str) -> Result<(), SourceError> {
    let pairs = parse_attributes(rest);
    match attribute(&pairs, "METHOD") {
        None | Some("NONE") => Ok(()),
        Some(method) => Err(unsupported(&format!("{method} encryption"))),
    }
}

pub fn parse_media(text: &str, base: &Url) -> Result<MediaPlaylist, SourceError> {
    if !text.trim_start().starts_with("#EXTM3U") {
        return Err(SourceError::MarkupChanged("not a playlist".into()));
    }
    let mut playlist = MediaPlaylist::default();
    let mut duration: Option<f64> = None;
    for line in text.lines().map(str::trim).filter(|line| !line.is_empty()) {
        if let Some(rest) = line.strip_prefix(KEY) {
            refuse_encryption(rest)?;
        } else if line.starts_with(MAP) {
            return Err(unsupported("fragmented segments"));
        } else if let Some(rest) = line.strip_prefix(SEGMENT_INFO) {
            duration = rest
                .split(',')
                .next()
                .and_then(|value| value.trim().parse().ok());
        } else if !line.starts_with('#') {
            let Some(seconds) = duration.take() else {
                continue;
            };
            let url = base
                .join(line)
                .map_err(|_| SourceError::MarkupChanged(format!("bad segment address {line}")))?;
            playlist.segments.push(Segment {
                url: url.into(),
                duration: seconds,
            });
        }
    }
    if playlist.segments.is_empty() {
        return Err(SourceError::MarkupChanged(
            "the playlist has no segments".into(),
        ));
    }
    Ok(playlist)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn base() -> Url {
        Url::parse("https://hls.test/p/abc/720/index.m3u8").unwrap()
    }

    #[test]
    fn segments_keep_their_order_duration_and_full_address() {
        let text = "#EXTM3U\n#EXT-X-TARGETDURATION:5\n#EXTINF:5.005,\nseg_000.ts.jpg\n\
#EXTINF:4.5,\nhttps://cdn.test/seg_001.ts\n#EXT-X-ENDLIST\n";
        let playlist = parse_media(text, &base()).unwrap();
        assert_eq!(playlist.segments.len(), 2);
        assert_eq!(
            playlist.segments[0].url,
            "https://hls.test/p/abc/720/seg_000.ts.jpg"
        );
        assert_eq!(playlist.segments[1].url, "https://cdn.test/seg_001.ts");
        assert!((playlist.duration() - 9.505).abs() < 1e-9);
    }

    #[test]
    fn encrypted_or_fragmented_playlists_are_refused_plainly() {
        let encrypted = "#EXTM3U\n#EXT-X-KEY:METHOD=AES-128,URI=\"k\"\n#EXTINF:5,\na.ts\n";
        assert!(matches!(
            parse_media(encrypted, &base()),
            Err(SourceError::Unsupported(_))
        ));
        let fragmented = "#EXTM3U\n#EXT-X-MAP:URI=\"init.mp4\"\n#EXTINF:5,\na.m4s\n";
        assert!(matches!(
            parse_media(fragmented, &base()),
            Err(SourceError::Unsupported(_))
        ));
        let clear = "#EXTM3U\n#EXT-X-KEY:METHOD=NONE\n#EXTINF:5,\na.ts\n";
        assert!(parse_media(clear, &base()).is_ok());
    }

    #[test]
    fn something_that_is_not_a_playlist_or_is_empty_means_the_site_changed() {
        for text in ["<html></html>", "#EXTM3U\n#EXT-X-ENDLIST\n"] {
            assert!(matches!(
                parse_media(text, &base()),
                Err(SourceError::MarkupChanged(_))
            ));
        }
    }
}
