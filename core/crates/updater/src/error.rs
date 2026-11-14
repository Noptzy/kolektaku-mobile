use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UpdateError {
    Network(String),
    BadManifest(String),
    Untrusted(String),
    HashMismatch,
    SizeMismatch { expected: u64, got: u64 },
    Storage(String),
    NoAsset,
}

impl fmt::Display for UpdateError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Network(message) => write!(formatter, "network: {message}"),
            Self::BadManifest(message) => write!(formatter, "manifest: {message}"),
            Self::Untrusted(message) => write!(formatter, "untrusted: {message}"),
            Self::HashMismatch => write!(formatter, "the download does not match its hash"),
            Self::SizeMismatch { expected, got } => {
                write!(formatter, "expected {expected} bytes but got {got}")
            }
            Self::Storage(message) => write!(formatter, "storage: {message}"),
            Self::NoAsset => write!(formatter, "no build for this device"),
        }
    }
}

impl std::error::Error for UpdateError {}

impl From<std::io::Error> for UpdateError {
    fn from(error: std::io::Error) -> Self {
        Self::Storage(error.to_string())
    }
}
