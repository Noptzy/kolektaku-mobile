use serde::{Deserialize, Serialize};

use super::MediaSummary;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum RelationType {
    Adaptation,
    Prequel,
    Sequel,
    Parent,
    SideStory,
    Character,
    Summary,
    Alternative,
    SpinOff,
    Other,
    Source,
    Compilation,
    Contains,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Relation {
    pub relation_type: RelationType,
    pub media: MediaSummary,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn side_story_uses_catalog_name_in_json() {
        assert_eq!(
            serde_json::to_string(&RelationType::SideStory).unwrap(),
            "\"SIDE_STORY\""
        );
    }
}
