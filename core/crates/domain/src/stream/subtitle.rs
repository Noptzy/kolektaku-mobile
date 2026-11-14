use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SubtitleVariant {
    Full,
    Forced,
    Sdh,
    Dubtitle,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct SubtitleTrack {
    pub label: String,
    pub language: Option<String>,
    pub variant: SubtitleVariant,
    pub url: String,
    pub is_default: bool,
}

const LANGUAGES: [(&str, &str); 22] = [
    ("indonesian", "id"),
    ("english", "en"),
    ("malay", "ms"),
    ("japanese", "ja"),
    ("arabic", "ar"),
    ("chinese", "zh"),
    ("korean", "ko"),
    ("thai", "th"),
    ("vietnamese", "vi"),
    ("filipino", "fil"),
    ("french", "fr"),
    ("german", "de"),
    ("italian", "it"),
    ("spanish", "es"),
    ("portuguese", "pt"),
    ("russian", "ru"),
    ("turkish", "tr"),
    ("dutch", "nl"),
    ("polish", "pl"),
    ("hindi", "hi"),
    ("tamil", "ta"),
    ("telugu", "te"),
];

const VARIANTS: [(&str, SubtitleVariant); 3] = [
    ("forced", SubtitleVariant::Forced),
    ("sdh", SubtitleVariant::Sdh),
    ("dubtitle", SubtitleVariant::Dubtitle),
];

fn variant_of(label: &str) -> SubtitleVariant {
    let lower = label.to_lowercase();
    VARIANTS
        .iter()
        .find(|(word, _)| lower.contains(word))
        .map_or(SubtitleVariant::Full, |(_, variant)| *variant)
}

fn language_of(label: &str) -> Option<String> {
    let first = label
        .split([' ', '-', '|'])
        .find(|word| !word.is_empty())?
        .to_lowercase();
    LANGUAGES
        .iter()
        .find(|(name, _)| *name == first)
        .map(|(_, code)| (*code).to_string())
}

impl SubtitleTrack {
    pub fn from_label(label: &str, url: impl Into<String>, is_default: bool) -> Self {
        let label = label.trim();
        Self {
            label: label.to_string(),
            language: language_of(label),
            variant: variant_of(label),
            url: url.into(),
            is_default,
        }
    }

    pub fn is_full(&self) -> bool {
        self.variant == SubtitleVariant::Full
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn track(label: &str) -> SubtitleTrack {
        SubtitleTrack::from_label(label, "https://s.test/a.vtt", false)
    }

    #[test]
    fn a_plain_label_is_a_full_track_in_that_language() {
        let indonesian = track("Indonesian");
        assert_eq!(indonesian.language.as_deref(), Some("id"));
        assert!(indonesian.is_full());
        assert_eq!(track("English").language.as_deref(), Some("en"));
        assert_eq!(track("Malay").language.as_deref(), Some("ms"));
    }

    #[test]
    fn variants_are_recognised_from_the_label() {
        assert_eq!(track("English - Forced").variant, SubtitleVariant::Forced);
        assert_eq!(track("English - SDH").variant, SubtitleVariant::Sdh);
        assert_eq!(
            track("French - Dubtitle").variant,
            SubtitleVariant::Dubtitle
        );
        assert_eq!(
            track("Hindi - Latin | Forced").variant,
            SubtitleVariant::Forced
        );
        assert_eq!(track("English - Forced").language.as_deref(), Some("en"));
    }

    #[test]
    fn compound_labels_use_the_first_word_for_the_language() {
        assert_eq!(
            track("Chinese - Simplified").language.as_deref(),
            Some("zh")
        );
        assert_eq!(
            track("Portuguese - Brazil | Dubtitle").language.as_deref(),
            Some("pt")
        );
        assert_eq!(
            track("Spanish - Latin America").language.as_deref(),
            Some("es")
        );
    }

    #[test]
    fn an_unknown_language_has_no_code_but_keeps_its_label() {
        let unknown = track("Klingon");
        assert_eq!(unknown.language, None);
        assert_eq!(unknown.label, "Klingon");
        assert_eq!(track("NOB").language, None);
    }

    #[test]
    fn the_label_is_trimmed_and_the_default_flag_kept() {
        let named = SubtitleTrack::from_label("  English  ", "https://s.test/b.vtt", true);
        assert_eq!(named.label, "English");
        assert!(named.is_default);
        assert_eq!(named.url, "https://s.test/b.vtt");
    }
}
