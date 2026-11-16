use super::keyed::keyed_enum;

keyed_enum! {
    TranslationLanguage {
        Off => "off",
        Indonesian => "id",
        English => "en",
        Malay => "ms",
        Japanese => "ja",
        Korean => "ko",
        Chinese => "zh",
        Arabic => "ar",
        Thai => "th",
        Vietnamese => "vi",
        Filipino => "tl",
        Spanish => "es",
        Portuguese => "pt",
        French => "fr",
        German => "de",
        Russian => "ru",
        Hindi => "hi",
        Turkish => "tr",
    } default Indonesian
}

impl TranslationLanguage {
    pub const ALL: [Self; 18] = [
        Self::Off,
        Self::Indonesian,
        Self::English,
        Self::Malay,
        Self::Japanese,
        Self::Korean,
        Self::Chinese,
        Self::Arabic,
        Self::Thai,
        Self::Vietnamese,
        Self::Filipino,
        Self::Spanish,
        Self::Portuguese,
        Self::French,
        Self::German,
        Self::Russian,
        Self::Hindi,
        Self::Turkish,
    ];

    pub fn is_on(self) -> bool {
        self != Self::Off
    }

    pub fn code(self) -> Option<&'static str> {
        match self {
            Self::Off => None,
            Self::Chinese => Some("zh-CN"),
            other => Some(other.key()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn there_are_seventeen_languages_and_an_off_switch() {
        assert_eq!(TranslationLanguage::ALL.len(), 18);
        let languages = TranslationLanguage::ALL
            .iter()
            .filter(|language| language.is_on())
            .count();
        assert_eq!(languages, 17);
    }

    #[test]
    fn every_value_survives_its_key() {
        for language in TranslationLanguage::ALL {
            assert_eq!(TranslationLanguage::parse(language.key()), Some(language));
        }
    }

    #[test]
    fn keys_are_distinct() {
        let mut keys: Vec<_> = TranslationLanguage::ALL.iter().map(|l| l.key()).collect();
        keys.sort_unstable();
        keys.dedup();
        assert_eq!(keys.len(), TranslationLanguage::ALL.len());
    }

    #[test]
    fn unknown_keys_are_not_guessed() {
        assert_eq!(TranslationLanguage::parse("klingon"), None);
        assert_eq!(TranslationLanguage::parse(""), None);
        assert_eq!(TranslationLanguage::parse("ID"), None);
    }

    #[test]
    fn indonesian_is_the_default() {
        assert_eq!(
            TranslationLanguage::default(),
            TranslationLanguage::Indonesian
        );
        assert!(TranslationLanguage::default().is_on());
    }

    #[test]
    fn off_has_no_service_code_and_the_rest_do() {
        assert_eq!(TranslationLanguage::Off.code(), None);
        for language in TranslationLanguage::ALL {
            assert_eq!(language.code().is_some(), language.is_on());
        }
    }

    #[test]
    fn the_service_codes_follow_the_language() {
        assert_eq!(TranslationLanguage::Indonesian.code(), Some("id"));
        assert_eq!(TranslationLanguage::English.code(), Some("en"));
        assert_eq!(TranslationLanguage::Chinese.code(), Some("zh-CN"));
        assert_eq!(TranslationLanguage::Filipino.code(), Some("tl"));
    }
}
