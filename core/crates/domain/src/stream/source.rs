use serde::{Deserialize, Serialize};

use super::{SkipRange, SubtitleTrack};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StreamKind {
    Hls,
    Mp4,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct StreamSource {
    pub url: String,
    pub kind: StreamKind,
    pub quality: u32,
    pub label: String,
    pub is_default: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct StreamSet {
    pub sources: Vec<StreamSource>,
    pub poster_url: Option<String>,
    pub headers: Vec<(String, String)>,
    pub subtitles: Vec<SubtitleTrack>,
    pub skips: Vec<SkipRange>,
}

impl StreamSet {
    pub fn from_sources(
        mut sources: Vec<StreamSource>,
        poster_url: Option<String>,
    ) -> Option<Self> {
        if sources.is_empty() {
            return None;
        }
        sources.sort_by_key(|source| std::cmp::Reverse(source.quality));
        for (index, source) in sources.iter_mut().enumerate() {
            source.is_default = index == 0;
        }
        Some(Self {
            sources,
            poster_url,
            headers: Vec::new(),
            subtitles: Vec::new(),
            skips: Vec::new(),
        })
    }

    pub fn with_headers(mut self, headers: Vec<(String, String)>) -> Self {
        self.headers = headers;
        self
    }

    pub fn with_subtitles(mut self, subtitles: Vec<SubtitleTrack>) -> Self {
        self.subtitles = subtitles;
        self
    }

    pub fn with_skips(mut self, skips: Vec<SkipRange>) -> Self {
        self.skips = skips;
        self
    }

    pub fn default_source(&self) -> &StreamSource {
        &self.sources[0]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn source(quality: u32) -> StreamSource {
        let url = format!("https://cdn/{quality}.mp4");
        StreamSource {
            url,
            kind: StreamKind::Mp4,
            quality,
            label: format!("{quality}p"),
            is_default: false,
        }
    }

    #[test]
    fn empty_sources_make_no_set() {
        assert_eq!(StreamSet::from_sources(Vec::new(), None), None);
    }

    #[test]
    fn sources_are_sorted_best_quality_first() {
        let set =
            StreamSet::from_sources(vec![source(360), source(1080), source(720)], None).unwrap();
        let qualities: Vec<u32> = set.sources.iter().map(|source| source.quality).collect();
        assert_eq!(qualities, vec![1080, 720, 360]);
    }

    #[test]
    fn a_new_set_has_no_extras_and_the_builders_fill_them() {
        let bare = StreamSet::from_sources(vec![source(720)], None).unwrap();
        assert!(bare.headers.is_empty() && bare.subtitles.is_empty() && bare.skips.is_empty());
        let skip = SkipRange::from_seconds(super::super::SkipKind::Intro, 1.0, 2.0).unwrap();
        let subtitle = SubtitleTrack::from_label("English", "https://s.test/a.vtt", true);
        let full = bare
            .with_headers(vec![("referer".into(), "https://e.test/".into())])
            .with_subtitles(vec![subtitle.clone()])
            .with_skips(vec![skip]);
        assert_eq!(full.headers.len(), 1);
        assert_eq!(full.subtitles, vec![subtitle]);
        assert_eq!(full.skips, vec![skip]);
    }

    #[test]
    fn only_the_best_source_is_default() {
        let set = StreamSet::from_sources(vec![source(480), source(720)], None).unwrap();
        let defaults: Vec<bool> = set.sources.iter().map(|source| source.is_default).collect();
        assert_eq!(defaults, vec![true, false]);
        assert_eq!(set.default_source().quality, 720);
    }
}
