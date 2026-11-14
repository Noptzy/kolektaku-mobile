use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum MediaListKind {
    Trending,
    Popular,
    Seasonal,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn uses_snake_case_in_json() {
        assert_eq!(
            serde_json::to_string(&MediaListKind::Trending).unwrap(),
            "\"trending\""
        );
    }
}
