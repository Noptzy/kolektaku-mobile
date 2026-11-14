use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum LinkKind {
    Info,
    Social,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ExternalLink {
    pub site: String,
    pub url: String,
    pub kind: LinkKind,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn kinds_use_catalog_names_in_json() {
        assert_eq!(serde_json::to_string(&LinkKind::Info).unwrap(), "\"INFO\"");
        assert_eq!(
            serde_json::to_string(&LinkKind::Social).unwrap(),
            "\"SOCIAL\""
        );
    }

    #[test]
    fn a_link_survives_json() {
        let link = ExternalLink {
            site: "Twitter".into(),
            url: "https://twitter.com/x".into(),
            kind: LinkKind::Social,
        };
        let json = serde_json::to_string(&link).unwrap();
        assert_eq!(serde_json::from_str::<ExternalLink>(&json).unwrap(), link);
    }
}
