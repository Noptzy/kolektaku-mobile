use crate::settings::TranslationLanguage;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LanguageRoute {
    from: Option<String>,
    target_code: &'static str,
}

impl LanguageRoute {
    pub fn new(from: Option<&str>, target: TranslationLanguage) -> Option<Self> {
        Some(Self {
            from: from
                .map(str::trim)
                .filter(|code| !code.is_empty())
                .map(|code| service_code(&code.to_lowercase())),
            target_code: target.code()?,
        })
    }

    pub fn detecting(target: TranslationLanguage) -> Option<Self> {
        Self::new(None, target)
    }

    pub fn from_code(&self) -> Option<&str> {
        self.from.as_deref()
    }

    pub fn target_code(&self) -> &'static str {
        self.target_code
    }

    pub fn needs_no_translation(&self) -> bool {
        self.from
            .as_deref()
            .is_some_and(|from| speaks_the_same(from, self.target_code))
    }
}

fn service_code(code: &str) -> String {
    match code {
        "fil" => "tl".to_string(),
        "zh" => "zh-CN".to_string(),
        other => other.to_string(),
    }
}

pub fn speaks_the_same(a: &str, b: &str) -> bool {
    primary_subtag(a).eq_ignore_ascii_case(primary_subtag(b))
}

fn primary_subtag(code: &str) -> &str {
    code.split(['-', '_']).next().unwrap_or(code)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_route_needs_a_real_target() {
        assert!(LanguageRoute::new(Some("en"), TranslationLanguage::Off).is_none());
        assert!(LanguageRoute::detecting(TranslationLanguage::Off).is_none());
        assert!(LanguageRoute::detecting(TranslationLanguage::Indonesian).is_some());
    }

    #[test]
    fn the_source_code_is_trimmed_lowercased_and_blank_means_detect() {
        let route = LanguageRoute::new(Some(" EN "), TranslationLanguage::Indonesian).unwrap();
        assert_eq!(route.from_code(), Some("en"));
        let blank = LanguageRoute::new(Some("  "), TranslationLanguage::Indonesian).unwrap();
        assert_eq!(blank.from_code(), None);
    }

    #[test]
    fn track_language_codes_are_turned_into_service_codes() {
        let filipino = LanguageRoute::new(Some("fil"), TranslationLanguage::English).unwrap();
        assert_eq!(filipino.from_code(), Some("tl"));
        let chinese = LanguageRoute::new(Some("zh"), TranslationLanguage::English).unwrap();
        assert_eq!(chinese.from_code(), Some("zh-CN"));
    }

    #[test]
    fn a_filipino_track_needs_no_translation_into_filipino() {
        let route = LanguageRoute::new(Some("fil"), TranslationLanguage::Filipino).unwrap();
        assert!(route.needs_no_translation());
    }

    #[test]
    fn the_target_code_comes_from_the_language() {
        let route = LanguageRoute::detecting(TranslationLanguage::Chinese).unwrap();
        assert_eq!(route.target_code(), "zh-CN");
    }

    #[test]
    fn the_same_language_needs_no_translation() {
        let same = LanguageRoute::new(Some("id"), TranslationLanguage::Indonesian).unwrap();
        assert!(same.needs_no_translation());
        let other = LanguageRoute::new(Some("en"), TranslationLanguage::Indonesian).unwrap();
        assert!(!other.needs_no_translation());
        let unknown = LanguageRoute::detecting(TranslationLanguage::Indonesian).unwrap();
        assert!(!unknown.needs_no_translation());
    }

    #[test]
    fn regional_variants_count_as_the_same_language() {
        assert!(speaks_the_same("zh-CN", "zh"));
        assert!(speaks_the_same("pt_BR", "pt"));
        assert!(!speaks_the_same("en", "ms"));
    }
}
