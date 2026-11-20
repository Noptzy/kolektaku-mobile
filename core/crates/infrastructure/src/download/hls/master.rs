use url::Url;

use super::attributes::{attribute, parse_attributes};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Variant {
    pub url: String,
    pub bandwidth: u64,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub audio_group: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AudioRendition {
    pub group: String,
    pub name: String,
    pub language: Option<String>,
    pub is_default: bool,
    pub url: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MasterPlaylist {
    pub variants: Vec<Variant>,
    pub audio: Vec<AudioRendition>,
}

const STREAM_INF: &str = "#EXT-X-STREAM-INF:";
const MEDIA: &str = "#EXT-X-MEDIA:";

pub fn is_master(text: &str) -> bool {
    text.lines().any(|line| line.trim().starts_with(STREAM_INF))
}

fn resolve(base: &Url, address: &str) -> Option<String> {
    base.join(address.trim()).ok().map(String::from)
}

fn side_of(resolution: Option<&str>, index: usize) -> Option<u32> {
    resolution?
        .split(['x', 'X'])
        .nth(index)?
        .trim()
        .parse()
        .ok()
}

fn audio_rendition(pairs: &[(String, String)], base: &Url) -> Option<AudioRendition> {
    if attribute(pairs, "TYPE") != Some("AUDIO") {
        return None;
    }
    Some(AudioRendition {
        group: attribute(pairs, "GROUP-ID")?.to_string(),
        name: attribute(pairs, "NAME").unwrap_or_default().to_string(),
        language: attribute(pairs, "LANGUAGE").map(str::to_string),
        is_default: attribute(pairs, "DEFAULT") == Some("YES"),
        url: attribute(pairs, "URI").and_then(|uri| resolve(base, uri)),
    })
}

pub fn parse_master(text: &str, base: &Url) -> MasterPlaylist {
    let mut playlist = MasterPlaylist::default();
    let mut pending: Option<Vec<(String, String)>> = None;
    for line in text.lines().map(str::trim).filter(|line| !line.is_empty()) {
        if let Some(rest) = line.strip_prefix(MEDIA) {
            playlist
                .audio
                .extend(audio_rendition(&parse_attributes(rest), base));
        } else if let Some(rest) = line.strip_prefix(STREAM_INF) {
            pending = Some(parse_attributes(rest));
        } else if !line.starts_with('#') {
            let Some(pairs) = pending.take() else {
                continue;
            };
            let Some(url) = resolve(base, line) else {
                continue;
            };
            playlist.variants.push(Variant {
                url,
                bandwidth: attribute(&pairs, "BANDWIDTH")
                    .and_then(|value| value.parse().ok())
                    .unwrap_or(0),
                width: side_of(attribute(&pairs, "RESOLUTION"), 0),
                height: side_of(attribute(&pairs, "RESOLUTION"), 1),
                audio_group: attribute(&pairs, "AUDIO").map(str::to_string),
            });
        }
    }
    playlist
}

#[cfg(test)]
mod tests {
    use super::*;

    const MASTER: &str = "#EXTM3U\n#EXT-X-VERSION:4\n\
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aud\",NAME=\"Japanese\",LANGUAGE=\"ja\",DEFAULT=YES,AUTOSELECT=YES,URI=\"aud/a0/index.m3u8\"\n\
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID=\"aud\",NAME=\"English\",LANGUAGE=\"en\",DEFAULT=NO,URI=\"aud/a1/index.m3u8\"\n\
#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\",NAME=\"English\",URI=\"subs/en.m3u8\"\n\
#EXT-X-STREAM-INF:BANDWIDTH=900000,RESOLUTION=640x360,AUDIO=\"aud\"\n360/index.m3u8\n\
#EXT-X-STREAM-INF:BANDWIDTH=3000000,RESOLUTION=1280x720,AUDIO=\"aud\"\nhttps://cdn.test/720/index.m3u8\n";

    fn base() -> Url {
        Url::parse("https://hls.test/p/abc/master.m3u8").unwrap()
    }

    #[test]
    fn variants_keep_their_bandwidth_height_audio_group_and_full_address() {
        let playlist = parse_master(MASTER, &base());
        assert_eq!(playlist.variants.len(), 2);
        assert_eq!(
            playlist.variants[0].url,
            "https://hls.test/p/abc/360/index.m3u8"
        );
        assert_eq!(playlist.variants[0].height, Some(360));
        assert_eq!(playlist.variants[0].width, Some(640));
        assert_eq!(playlist.variants[0].bandwidth, 900_000);
        assert_eq!(playlist.variants[0].audio_group.as_deref(), Some("aud"));
        assert_eq!(playlist.variants[1].url, "https://cdn.test/720/index.m3u8");
    }

    #[test]
    fn only_audio_renditions_are_kept_with_their_default_flag() {
        let playlist = parse_master(MASTER, &base());
        assert_eq!(playlist.audio.len(), 2);
        assert!(playlist.audio[0].is_default);
        assert_eq!(playlist.audio[0].language.as_deref(), Some("ja"));
        assert_eq!(
            playlist.audio[1].url.as_deref(),
            Some("https://hls.test/p/abc/aud/a1/index.m3u8")
        );
    }

    #[test]
    fn a_master_is_told_apart_from_a_media_playlist() {
        assert!(is_master(MASTER));
        assert!(!is_master("#EXTM3U\n#EXTINF:5.0,\nseg.ts\n"));
    }
}
