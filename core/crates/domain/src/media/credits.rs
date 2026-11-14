use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum CharacterRole {
    Main,
    Supporting,
    Background,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct VoiceActor {
    pub id: u64,
    pub name: String,
    pub image_url: Option<String>,
    pub language: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Character {
    pub id: u64,
    pub name: String,
    pub image_url: Option<String>,
    pub role: CharacterRole,
    pub voice_actors: Vec<VoiceActor>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Staff {
    pub id: u64,
    pub name: String,
    pub role: String,
    pub image_url: Option<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn role_uses_catalog_names_in_json() {
        assert_eq!(
            serde_json::to_string(&CharacterRole::Supporting).unwrap(),
            "\"SUPPORTING\""
        );
    }

    #[test]
    fn character_keeps_its_voice_actors() {
        let actor = VoiceActor {
            id: 9,
            name: "Actor".into(),
            image_url: None,
            language: "Japanese".into(),
        };
        let character = Character {
            id: 1,
            name: "Mitsuha".into(),
            image_url: None,
            role: CharacterRole::Main,
            voice_actors: vec![actor],
        };
        let json = serde_json::to_string(&character).unwrap();
        assert_eq!(serde_json::from_str::<Character>(&json).unwrap(), character);
    }
}
