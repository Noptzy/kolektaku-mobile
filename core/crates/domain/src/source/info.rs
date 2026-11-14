use serde::{Deserialize, Serialize};

use super::SourceId;
use crate::media::MediaKind;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum StreamSupport {
    None,
    Direct,
    NeedsWebView,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Capabilities {
    pub search: bool,
    pub latest: bool,
    pub genres: bool,
    pub stream: StreamSupport,
}

impl Capabilities {
    pub fn full(stream: StreamSupport) -> Self {
        Self {
            search: true,
            latest: true,
            genres: true,
            stream,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SourceInfo {
    pub id: SourceId,
    pub name: String,
    pub kind: MediaKind,
    pub priority: u8,
    pub capabilities: Capabilities,
    pub summary: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_capabilities_enable_every_listing_feature() {
        let capabilities = Capabilities::full(StreamSupport::NeedsWebView);
        assert!(capabilities.search && capabilities.latest && capabilities.genres);
        assert_eq!(capabilities.stream, StreamSupport::NeedsWebView);
    }

    #[test]
    fn stream_support_uses_snake_case_in_json() {
        assert_eq!(
            serde_json::to_string(&StreamSupport::NeedsWebView).unwrap(),
            "\"needs_web_view\""
        );
    }
}
