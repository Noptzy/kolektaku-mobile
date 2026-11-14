use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SourceSettings {
    pub id: String,
    pub base_url: String,
    pub api_url: Option<String>,
    pub enabled: bool,
    pub priority: u8,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RemoteSource {
    pub id: String,
    pub base_url: Option<String>,
    pub api_url: Option<String>,
    pub enabled: Option<bool>,
    pub priority: Option<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RemoteConfig {
    #[serde(default)]
    pub version: u32,
    pub sources: Vec<RemoteSource>,
}

impl RemoteConfig {
    pub fn parse(text: &str) -> Option<Self> {
        serde_json::from_str(text).ok()
    }

    pub fn to_json(&self) -> String {
        serde_json::to_string_pretty(self).unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_the_file_the_release_ships() {
        let text = r#"{"version":1,"sources":[
            {"id":"kuramanime","baseUrl":"https://v21.kuramanime.ing","enabled":true,"priority":1},
            {"id":"komiku","enabled":false}]}"#;
        let config = RemoteConfig::parse(text).unwrap();
        assert_eq!(config.version, 1);
        assert_eq!(
            config.sources[0].base_url.as_deref(),
            Some("https://v21.kuramanime.ing")
        );
        assert_eq!(config.sources[1].enabled, Some(false));
        assert_eq!(config.sources[1].priority, None);
    }

    #[test]
    fn anything_that_is_not_a_config_is_rejected() {
        for text in [
            "",
            "not json",
            "{}",
            r#"{"sources":"x"}"#,
            r#"{"sources":[{"baseUrl":"x"}]}"#,
        ] {
            assert_eq!(RemoteConfig::parse(text), None, "{text}");
        }
    }

    #[test]
    fn survives_a_round_trip() {
        let config = RemoteConfig {
            version: 2,
            sources: vec![RemoteSource {
                id: "a".into(),
                base_url: Some("https://a.example".into()),
                api_url: None,
                enabled: Some(true),
                priority: Some(3),
            }],
        };
        assert_eq!(RemoteConfig::parse(&config.to_json()), Some(config));
    }
}
