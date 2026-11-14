use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct MediaTitle {
    pub romaji: String,
    pub english: Option<String>,
    pub native: Option<String>,
}

impl MediaTitle {
    pub fn new(romaji: impl Into<String>) -> Self {
        Self {
            romaji: romaji.into(),
            english: None,
            native: None,
        }
    }

    pub fn names(&self) -> Vec<&str> {
        [
            Some(self.romaji.as_str()),
            self.english.as_deref(),
            self.native.as_deref(),
        ]
        .into_iter()
        .flatten()
        .filter(|name| !name.trim().is_empty())
        .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn names_lists_romaji_english_native_in_order() {
        let title = MediaTitle {
            romaji: "Kimi no Na wa.".into(),
            english: Some("Your Name.".into()),
            native: Some("君の名は。".into()),
        };
        assert_eq!(
            title.names(),
            vec!["Kimi no Na wa.", "Your Name.", "君の名は。"]
        );
    }

    #[test]
    fn names_skips_missing_and_blank() {
        let title = MediaTitle {
            romaji: "One Piece".into(),
            english: Some("  ".into()),
            native: None,
        };
        assert_eq!(title.names(), vec!["One Piece"]);
    }
}
