use std::fmt;

use domain::error::{SourceError, StorageError};
use updater::UpdateError;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BridgeErrorKind {
    Network,
    Unavailable,
    MarkupChanged,
    ChallengeRequired,
    NotFound,
    RateLimited,
    QuotaExceeded,
    Unsupported,
    Storage,
    NotReady,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BridgeError {
    pub kind: BridgeErrorKind,
    pub detail: String,
    pub retry_after_secs: Option<u64>,
}

impl BridgeError {
    pub fn new(kind: BridgeErrorKind, detail: impl Into<String>) -> Self {
        Self {
            kind,
            detail: detail.into(),
            retry_after_secs: None,
        }
    }

    pub fn not_found(detail: impl Into<String>) -> Self {
        Self::new(BridgeErrorKind::NotFound, detail)
    }

    pub fn not_ready() -> Self {
        Self::new(BridgeErrorKind::NotReady, "the core is not initialised")
    }
}

impl fmt::Display for BridgeError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{:?}: {}", self.kind, self.detail)
    }
}

impl std::error::Error for BridgeError {}

impl From<SourceError> for BridgeError {
    fn from(error: SourceError) -> Self {
        use BridgeErrorKind as Kind;
        match error {
            SourceError::Network(detail) => Self::new(Kind::Network, detail),
            SourceError::Unavailable(detail) => Self::new(Kind::Unavailable, detail),
            SourceError::MarkupChanged(detail) => Self::new(Kind::MarkupChanged, detail),
            SourceError::ChallengeRequired(detail) => Self::new(Kind::ChallengeRequired, detail),
            SourceError::NotFound(detail) => Self::new(Kind::NotFound, detail),
            SourceError::RateLimited { retry_after_secs } => Self {
                retry_after_secs,
                ..Self::new(Kind::RateLimited, "rate limited")
            },
            SourceError::QuotaExceeded => Self::new(Kind::QuotaExceeded, "quota exceeded"),
            SourceError::Unsupported(detail) => Self::new(Kind::Unsupported, detail),
        }
    }
}

impl From<UpdateError> for BridgeError {
    fn from(error: UpdateError) -> Self {
        use BridgeErrorKind as Kind;
        let detail = error.to_string();
        match error {
            UpdateError::Network(_) => Self::new(Kind::Network, detail),
            UpdateError::Storage(_) => Self::new(Kind::Storage, detail),
            UpdateError::NoAsset => Self::new(Kind::Unsupported, detail),
            UpdateError::BadManifest(_)
            | UpdateError::Untrusted(_)
            | UpdateError::HashMismatch
            | UpdateError::SizeMismatch { .. } => Self::new(Kind::Unavailable, detail),
        }
    }
}

impl From<StorageError> for BridgeError {
    fn from(error: StorageError) -> Self {
        Self::new(BridgeErrorKind::Storage, error.0)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn kind_and_detail(error: SourceError) -> (BridgeErrorKind, String) {
        let converted = BridgeError::from(error);
        (converted.kind, converted.detail)
    }

    #[test]
    fn every_source_error_keeps_its_meaning_and_message() {
        use BridgeErrorKind as Kind;
        let cases = [
            (SourceError::Network("a".into()), Kind::Network, "a"),
            (SourceError::Unavailable("b".into()), Kind::Unavailable, "b"),
            (
                SourceError::MarkupChanged("c".into()),
                Kind::MarkupChanged,
                "c",
            ),
            (
                SourceError::ChallengeRequired("d".into()),
                Kind::ChallengeRequired,
                "d",
            ),
            (SourceError::NotFound("e".into()), Kind::NotFound, "e"),
            (SourceError::Unsupported("f".into()), Kind::Unsupported, "f"),
        ];
        for (source, kind, detail) in cases {
            assert_eq!(kind_and_detail(source), (kind, detail.to_string()));
        }
    }

    #[test]
    fn rate_limiting_keeps_the_retry_hint_and_quota_has_its_own_kind() {
        let limited = BridgeError::from(SourceError::RateLimited {
            retry_after_secs: Some(9),
        });
        assert_eq!(limited.kind, BridgeErrorKind::RateLimited);
        assert_eq!(limited.retry_after_secs, Some(9));
        assert_eq!(
            BridgeError::from(SourceError::QuotaExceeded).kind,
            BridgeErrorKind::QuotaExceeded
        );
        assert_eq!(
            BridgeError::from(SourceError::QuotaExceeded).retry_after_secs,
            None
        );
    }

    #[test]
    fn update_failures_map_to_the_matching_kinds() {
        use BridgeErrorKind as Kind;
        let cases = [
            (UpdateError::Network("x".into()), Kind::Network),
            (UpdateError::Storage("x".into()), Kind::Storage),
            (UpdateError::NoAsset, Kind::Unsupported),
            (UpdateError::BadManifest("x".into()), Kind::Unavailable),
            (UpdateError::Untrusted("x".into()), Kind::Unavailable),
            (UpdateError::HashMismatch, Kind::Unavailable),
            (
                UpdateError::SizeMismatch {
                    expected: 2,
                    got: 1,
                },
                Kind::Unavailable,
            ),
        ];
        for (error, kind) in cases {
            assert_eq!(BridgeError::from(error).kind, kind);
        }
    }

    #[test]
    fn storage_failures_carry_their_message() {
        let error = BridgeError::from(StorageError("disk full".into()));
        assert_eq!(error.kind, BridgeErrorKind::Storage);
        assert!(error.to_string().contains("disk full"));
    }

    #[test]
    fn the_helpers_build_the_expected_kinds() {
        assert_eq!(BridgeError::not_found("x").kind, BridgeErrorKind::NotFound);
        assert_eq!(BridgeError::not_ready().kind, BridgeErrorKind::NotReady);
    }
}
