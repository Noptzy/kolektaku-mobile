use serde::{Deserialize, Serialize};

use super::phase::DownloadPhase;
use crate::media::{MediaKind, MediaRef};
use crate::stream::StreamSet;

const REFUSED_IN_FILE_NAMES: [char; 9] = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'];
const LONGEST_TITLE: usize = 80;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DownloadTarget {
    pub media: MediaRef,
    pub kind: MediaKind,
    pub title: String,
    pub episode: f64,
    pub cover_url: Option<String>,
}

impl DownloadTarget {
    pub fn file_stem(&self) -> String {
        let cleaned: String = self
            .title
            .chars()
            .map(|letter| {
                if REFUSED_IN_FILE_NAMES.contains(&letter) || letter.is_control() {
                    ' '
                } else {
                    letter
                }
            })
            .collect();
        let title = cleaned.split_whitespace().collect::<Vec<_>>().join(" ");
        let title: String = title.chars().take(LONGEST_TITLE).collect();
        format!("{} - Episode {}", title.trim(), episode_text(self.episode))
    }

    pub fn is_same_episode(&self, other: &DownloadTarget) -> bool {
        self.media == other.media && self.episode == other.episode
    }
}

fn episode_text(episode: f64) -> String {
    if episode.fract() == 0.0 {
        format!("{:02}", episode as i64)
    } else {
        episode.to_string()
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct DownloadJob {
    pub id: i64,
    pub target: DownloadTarget,
    pub stream: StreamSet,
    pub phase: DownloadPhase,
    pub progress: f32,
    pub bytes: u64,
    pub file_path: Option<String>,
    pub error: Option<String>,
    pub created_at_secs: u64,
}

impl DownloadJob {
    pub fn queued(target: DownloadTarget, stream: StreamSet, now_secs: u64) -> Self {
        Self {
            id: 0,
            target,
            stream,
            phase: DownloadPhase::Queued,
            progress: 0.0,
            bytes: 0,
            file_path: None,
            error: None,
            created_at_secs: now_secs,
        }
    }

    pub fn restarted(mut self, stream: StreamSet) -> Self {
        self.stream = stream;
        self.phase = DownloadPhase::Queued;
        self.progress = 0.0;
        self.bytes = 0;
        self.error = None;
        self.file_path = None;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::media::MediaId;

    fn target(title: &str, episode: f64) -> DownloadTarget {
        DownloadTarget {
            media: MediaRef::catalog(MediaId::new(1).unwrap()),
            kind: MediaKind::Anime,
            title: title.into(),
            episode,
            cover_url: None,
        }
    }

    #[test]
    fn the_file_name_has_the_title_and_a_padded_episode() {
        assert_eq!(target("Frieren", 3.0).file_stem(), "Frieren - Episode 03");
        assert_eq!(
            target("Frieren", 12.5).file_stem(),
            "Frieren - Episode 12.5"
        );
    }

    #[test]
    fn characters_a_file_system_refuses_are_replaced() {
        assert_eq!(
            target("Re:Zero / Kara? <Hajimeru>", 1.0).file_stem(),
            "Re Zero Kara Hajimeru - Episode 01"
        );
    }

    #[test]
    fn a_very_long_title_is_shortened() {
        let stem = target(&"a".repeat(300), 1.0).file_stem();
        assert!(stem.len() < 100);
    }

    #[test]
    fn the_same_episode_of_the_same_title_is_recognised() {
        assert!(target("A", 1.0).is_same_episode(&target("B", 1.0)));
        assert!(!target("A", 1.0).is_same_episode(&target("A", 2.0)));
    }
}
