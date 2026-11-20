use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum DownloadPhase {
    Queued,
    Fetching,
    Subtitles,
    Muxing,
    Done,
    Failed,
    Cancelled,
}

impl DownloadPhase {
    pub fn is_active(self) -> bool {
        matches!(
            self,
            Self::Queued | Self::Fetching | Self::Subtitles | Self::Muxing
        )
    }

    pub fn is_working(self) -> bool {
        self.is_active() && self != Self::Queued
    }

    pub fn can_retry(self) -> bool {
        matches!(self, Self::Failed | Self::Cancelled)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn waiting_and_working_phases_are_active() {
        for phase in [
            DownloadPhase::Queued,
            DownloadPhase::Fetching,
            DownloadPhase::Subtitles,
            DownloadPhase::Muxing,
        ] {
            assert!(phase.is_active(), "{phase:?}");
        }
        for phase in [
            DownloadPhase::Done,
            DownloadPhase::Failed,
            DownloadPhase::Cancelled,
        ] {
            assert!(!phase.is_active(), "{phase:?}");
        }
    }

    #[test]
    fn a_queued_download_is_active_but_not_yet_working() {
        assert!(!DownloadPhase::Queued.is_working());
        assert!(DownloadPhase::Fetching.is_working());
        assert!(!DownloadPhase::Done.is_working());
    }

    #[test]
    fn only_a_failed_or_cancelled_download_can_be_retried() {
        assert!(DownloadPhase::Failed.can_retry());
        assert!(DownloadPhase::Cancelled.can_retry());
        assert!(!DownloadPhase::Done.can_retry());
        assert!(!DownloadPhase::Fetching.can_retry());
    }
}
