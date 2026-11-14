use domain::media::{Character, CharacterRole, Staff, VoiceActor};

use crate::catalog::anilist::schema::{RawCharacterEdge, RawEdges, RawStaffEdge};

const DEFAULT_LANGUAGE: &str = "Japanese";

pub fn map_characters(raw: Option<RawEdges<RawCharacterEdge>>) -> Vec<Character> {
    raw.and_then(|edges| edges.edges)
        .unwrap_or_default()
        .into_iter()
        .map(|edge| Character {
            id: edge.node.id,
            name: edge.node.name.full.unwrap_or_default(),
            image_url: edge.node.image.and_then(|image| image.large),
            role: edge.role.unwrap_or(CharacterRole::Background),
            voice_actors: edge
                .voice_actors
                .unwrap_or_default()
                .into_iter()
                .map(|actor| VoiceActor {
                    id: actor.id,
                    name: actor.name.full.unwrap_or_default(),
                    image_url: actor.image.and_then(|image| image.large),
                    language: actor.language_v2.unwrap_or_else(|| DEFAULT_LANGUAGE.into()),
                })
                .collect(),
        })
        .collect()
}

pub fn map_staff(raw: Option<RawEdges<RawStaffEdge>>) -> Vec<Staff> {
    raw.and_then(|edges| edges.edges)
        .unwrap_or_default()
        .into_iter()
        .map(|edge| Staff {
            id: edge.node.id,
            name: edge.node.name.full.unwrap_or_default(),
            role: edge.role.unwrap_or_default(),
            image_url: edge.node.image.and_then(|image| image.large),
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn characters(json: &str) -> Vec<Character> {
        map_characters(Some(serde_json::from_str(json).unwrap()))
    }

    #[test]
    fn a_character_keeps_role_image_and_voice_actors() {
        let list = characters(
            r#"{"edges":[{"role":"MAIN","node":{"id":1,"name":{"full":"Tanjirou"},"image":{"large":"t.jpg"}},
            "voiceActors":[{"id":9,"name":{"full":"Natsuki Hanae"},"image":null,"languageV2":"Japanese"}]}]}"#,
        );
        assert_eq!(list[0].name, "Tanjirou");
        assert_eq!(list[0].role, CharacterRole::Main);
        assert_eq!(list[0].image_url.as_deref(), Some("t.jpg"));
        assert_eq!(list[0].voice_actors[0].name, "Natsuki Hanae");
    }

    #[test]
    fn missing_pieces_get_safe_defaults() {
        let list = characters(
            r#"{"edges":[{"role":"CAMEO","node":{"id":2,"name":{"full":null}},
            "voiceActors":[{"id":3,"name":{"full":"X"},"languageV2":null}]}]}"#,
        );
        assert_eq!(list[0].name, "");
        assert_eq!(list[0].role, CharacterRole::Background);
        assert_eq!(list[0].voice_actors[0].language, "Japanese");
        assert!(map_characters(None).is_empty());
    }

    #[test]
    fn staff_without_a_role_has_an_empty_one() {
        let raw: RawEdges<RawStaffEdge> = serde_json::from_str(
            r#"{"edges":[{"role":null,"node":{"id":4,"name":{"full":"Director"}}}]}"#,
        )
        .unwrap();
        let staff = map_staff(Some(raw));
        assert_eq!(staff[0].role, "");
        assert_eq!(staff[0].name, "Director");
        assert!(map_staff(None).is_empty());
    }
}
