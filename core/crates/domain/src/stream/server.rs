use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ServerVariant {
    Sub,
    Dub,
}

impl ServerVariant {
    pub fn key(self) -> &'static str {
        match self {
            Self::Sub => "sub",
            Self::Dub => "dub",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct EpisodeServer {
    pub id: String,
    pub label: String,
    #[serde(default)]
    pub variant: Option<ServerVariant>,
    #[serde(default)]
    pub audio: Option<String>,
}

impl EpisodeServer {
    pub fn new(id: impl Into<String>, label: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            label: label.into(),
            variant: None,
            audio: None,
        }
    }

    pub fn with_variant(mut self, variant: ServerVariant) -> Self {
        self.variant = Some(variant);
        self
    }

    pub fn with_audio(mut self, language: impl Into<String>) -> Self {
        self.audio = Some(language.into());
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn new_keeps_id_and_label() {
        let server = EpisodeServer::new("kuramadrive", "Kuramadrive");
        assert_eq!(
            (server.id.as_str(), server.label.as_str()),
            ("kuramadrive", "Kuramadrive")
        );
        assert_eq!(server.variant, None);
        assert_eq!(server.audio, None);
    }

    #[test]
    fn the_audio_language_can_be_attached() {
        let server = EpisodeServer::new("dub-1", "x").with_audio("en");
        assert_eq!(server.audio.as_deref(), Some("en"));
    }

    #[test]
    fn a_variant_can_be_attached() {
        let server = EpisodeServer::new("dub-1", "x").with_variant(ServerVariant::Dub);
        assert_eq!(server.variant, Some(ServerVariant::Dub));
        assert_eq!(ServerVariant::Dub.key(), "dub");
        assert_eq!(ServerVariant::Sub.key(), "sub");
    }

    #[test]
    fn an_old_stored_server_without_a_variant_still_loads() {
        let server: EpisodeServer = serde_json::from_str(r#"{"id":"a","label":"b"}"#).unwrap();
        assert_eq!(server.variant, None);
    }
}
