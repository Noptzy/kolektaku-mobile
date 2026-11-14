use thiserror::Error;

#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum SourceError {
    #[error("network error: {0}")]
    Network(String),
    #[error("source unavailable: {0}")]
    Unavailable(String),
    #[error("page structure changed: {0}")]
    MarkupChanged(String),
    #[error("site challenge required: {0}")]
    ChallengeRequired(String),
    #[error("not found: {0}")]
    NotFound(String),
    #[error("rate limited")]
    RateLimited { retry_after_secs: Option<u64> },
    #[error("quota exceeded")]
    QuotaExceeded,
    #[error("unsupported: {0}")]
    Unsupported(String),
}

impl SourceError {
    pub fn counts_against_source_health(&self) -> bool {
        !matches!(
            self,
            Self::NotFound(_) | Self::Unsupported(_) | Self::QuotaExceeded
        )
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn failures_of_the_site_count_against_its_health() {
        assert!(SourceError::Network("timeout".into()).counts_against_source_health());
        assert!(SourceError::MarkupChanged("no list".into()).counts_against_source_health());
        assert!(
            SourceError::RateLimited {
                retry_after_secs: Some(5)
            }
            .counts_against_source_health()
        );
    }

    #[test]
    fn missing_items_and_unsupported_features_do_not() {
        assert!(!SourceError::NotFound("x".into()).counts_against_source_health());
        assert!(!SourceError::Unsupported("genres".into()).counts_against_source_health());
        assert!(!SourceError::QuotaExceeded.counts_against_source_health());
    }

    #[test]
    fn display_names_the_kind_and_detail() {
        assert_eq!(
            SourceError::NotFound("episode 9".into()).to_string(),
            "not found: episode 9"
        );
    }
}
