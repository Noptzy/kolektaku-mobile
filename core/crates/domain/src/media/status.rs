use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum MediaStatus {
    Finished,
    Releasing,
    NotYetReleased,
    Cancelled,
    Hiatus,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_catalog_names_in_json() {
        let json = serde_json::to_string(&MediaStatus::NotYetReleased).unwrap();
        assert_eq!(json, "\"NOT_YET_RELEASED\"");
    }
}
