use domain::media::{CharacterRole, RelationType};
use serde::Deserialize;

use super::lenient::lenient;
use super::summary::{RawImage, RawSummary};

#[derive(Debug, Deserialize)]
pub struct RawEdges<T> {
    pub edges: Option<Vec<T>>,
}

#[derive(Debug, Deserialize)]
pub struct RawName {
    pub full: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RawPerson {
    pub id: u64,
    pub name: RawName,
    pub image: Option<RawImage>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawVoiceActor {
    pub id: u64,
    pub name: RawName,
    pub image: Option<RawImage>,
    pub language_v2: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawCharacterEdge {
    #[serde(default, deserialize_with = "lenient")]
    pub role: Option<CharacterRole>,
    pub node: RawPerson,
    pub voice_actors: Option<Vec<RawVoiceActor>>,
}

#[derive(Debug, Deserialize)]
pub struct RawStaffEdge {
    pub role: Option<String>,
    pub node: RawPerson,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawRelationEdge {
    #[serde(default, deserialize_with = "lenient")]
    pub relation_type: Option<RelationType>,
    pub node: Option<RawSummary>,
}

#[derive(Debug, Deserialize)]
pub struct RawRecommendations {
    pub nodes: Option<Vec<RawRecommendation>>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RawRecommendation {
    pub media_recommendation: Option<RawSummary>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn unknown_roles_and_relation_types_become_none() {
        let role: RawCharacterEdge =
            serde_json::from_str(r#"{"role":"CAMEO","node":{"id":1,"name":{"full":"A"}}}"#)
                .unwrap();
        assert_eq!(role.role, None);
        let relation: RawRelationEdge =
            serde_json::from_str(r#"{"relationType":"MYSTERY","node":null}"#).unwrap();
        assert_eq!(relation.relation_type, None);
        assert!(relation.node.is_none());
    }

    #[test]
    fn a_character_without_voice_actors_is_fine() {
        let edge: RawCharacterEdge =
            serde_json::from_str(r#"{"role":"MAIN","node":{"id":2,"name":{"full":null}}}"#)
                .unwrap();
        assert_eq!(edge.role, Some(CharacterRole::Main));
        assert!(edge.voice_actors.is_none());
    }
}
