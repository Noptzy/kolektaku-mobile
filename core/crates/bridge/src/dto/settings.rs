use domain::settings::{
    AccentColor, AppSettings, QualityPreference, ReadingSize, ReadingSpacing, SubtitleBoxColor,
    SubtitleBoxOpacity, SubtitleColor, SubtitleEdge, SubtitleLanguage, SubtitleSize,
    TranslationLanguage,
};
use domain::source::SourceId;

macro_rules! mirror_enum {
    ($dto:ident <-> $domain:ident { $($variant:ident),+ $(,)? }) => {
        #[derive(Debug, Clone, Copy, PartialEq, Eq)]
        pub enum $dto {
            $($variant),+
        }

        impl From<$domain> for $dto {
            fn from(value: $domain) -> Self {
                match value {
                    $($domain::$variant => Self::$variant),+
                }
            }
        }

        impl From<$dto> for $domain {
            fn from(value: $dto) -> Self {
                match value {
                    $($dto::$variant => Self::$variant),+
                }
            }
        }
    };
}

mirror_enum!(SubtitleLanguageDto <-> SubtitleLanguage { Indonesian, English, Off });
mirror_enum!(SubtitleSizeDto <-> SubtitleSize { Small, Medium, Large, Huge });
mirror_enum!(SubtitleColorDto <-> SubtitleColor { White, Yellow, Green, Cyan, Pink });
mirror_enum!(SubtitleEdgeDto <-> SubtitleEdge { None, Shadow, Outline });
mirror_enum!(SubtitleBoxColorDto <-> SubtitleBoxColor { Black, Gray, Navy });
mirror_enum!(SubtitleBoxOpacityDto <-> SubtitleBoxOpacity { Off, Light, Medium, Full });
mirror_enum!(QualityDto <-> QualityPreference { Auto, P1080, P720, P480, P360 });
mirror_enum!(ReadingSizeDto <-> ReadingSize { Smallest, Small, Medium, Large, Largest });
mirror_enum!(ReadingSpacingDto <-> ReadingSpacing { Tight, Normal, Loose });
mirror_enum!(TranslationLanguageDto <-> TranslationLanguage {
    Off, Indonesian, English, Malay, Japanese, Korean, Chinese, Arabic, Thai, Vietnamese,
    Filipino, Spanish, Portuguese, French, German, Russian, Hindi, Turkish
});

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SettingsDto {
    pub prefers_anime: bool,
    pub anime_source: Option<String>,
    pub subtitle_language: SubtitleLanguageDto,
    pub subtitle_size: SubtitleSizeDto,
    pub subtitle_color: SubtitleColorDto,
    pub subtitle_edge: SubtitleEdgeDto,
    pub subtitle_box_color: SubtitleBoxColorDto,
    pub subtitle_box_opacity: SubtitleBoxOpacityDto,
    pub quality: QualityDto,
    pub auto_next: bool,
    pub auto_skip: bool,
    pub accent: String,
    pub translation: TranslationLanguageDto,
    pub reading_size: ReadingSizeDto,
    pub reading_spacing: ReadingSpacingDto,
    pub continuous_reading: bool,
}

impl From<&AppSettings> for SettingsDto {
    fn from(settings: &AppSettings) -> Self {
        Self {
            prefers_anime: settings.prefers_anime,
            anime_source: settings.anime_source.as_ref().map(ToString::to_string),
            subtitle_language: settings.subtitle_language.into(),
            subtitle_size: settings.subtitle_size.into(),
            subtitle_color: settings.subtitle_color.into(),
            subtitle_edge: settings.subtitle_edge.into(),
            subtitle_box_color: settings.subtitle_box_color.into(),
            subtitle_box_opacity: settings.subtitle_box_opacity.into(),
            quality: settings.quality.into(),
            auto_next: settings.auto_next,
            auto_skip: settings.auto_skip,
            accent: settings.accent.hex(),
            translation: settings.translation.into(),
            reading_size: settings.reading_size.into(),
            reading_spacing: settings.reading_spacing.into(),
            continuous_reading: settings.continuous_reading,
        }
    }
}

impl From<&SettingsDto> for AppSettings {
    fn from(dto: &SettingsDto) -> Self {
        Self {
            prefers_anime: dto.prefers_anime,
            anime_source: dto.anime_source.as_deref().map(SourceId::new),
            subtitle_language: dto.subtitle_language.into(),
            subtitle_size: dto.subtitle_size.into(),
            subtitle_color: dto.subtitle_color.into(),
            subtitle_edge: dto.subtitle_edge.into(),
            subtitle_box_color: dto.subtitle_box_color.into(),
            subtitle_box_opacity: dto.subtitle_box_opacity.into(),
            quality: dto.quality.into(),
            auto_next: dto.auto_next,
            auto_skip: dto.auto_skip,
            accent: AccentColor::parse(&dto.accent).unwrap_or_default(),
            translation: dto.translation.into(),
            reading_size: dto.reading_size.into(),
            reading_spacing: dto.reading_spacing.into(),
            continuous_reading: dto.continuous_reading,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_defaults_survive_the_dto_and_back() {
        let defaults = AppSettings::default();
        let back = AppSettings::from(&SettingsDto::from(&defaults));
        assert_eq!(back, defaults);
    }

    #[test]
    fn a_changed_set_survives_the_dto_and_back() {
        let changed = AppSettings {
            prefers_anime: false,
            anime_source: Some(SourceId::new("x")),
            subtitle_language: SubtitleLanguage::Off,
            subtitle_size: SubtitleSize::Huge,
            subtitle_color: SubtitleColor::Cyan,
            subtitle_edge: SubtitleEdge::Outline,
            subtitle_box_color: SubtitleBoxColor::Gray,
            subtitle_box_opacity: SubtitleBoxOpacity::Light,
            quality: QualityPreference::P360,
            auto_next: false,
            auto_skip: true,
            accent: AccentColor::parse("#00FF00").unwrap(),
            translation: TranslationLanguage::Korean,
            reading_size: ReadingSize::Largest,
            reading_spacing: ReadingSpacing::Tight,
            continuous_reading: false,
        };
        let dto = SettingsDto::from(&changed);
        assert_eq!(dto.anime_source.as_deref(), Some("x"));
        assert_eq!(dto.quality, QualityDto::P360);
        assert_eq!(dto.translation, TranslationLanguageDto::Korean);
        assert_eq!(dto.reading_size, ReadingSizeDto::Largest);
        assert_eq!(dto.reading_spacing, ReadingSpacingDto::Tight);
        assert_eq!(AppSettings::from(&dto), changed);
    }

    #[test]
    fn every_translation_language_survives_the_dto_and_back() {
        for language in TranslationLanguage::ALL {
            let settings = AppSettings {
                translation: language,
                ..AppSettings::default()
            };
            let back = AppSettings::from(&SettingsDto::from(&settings));
            assert_eq!(back.translation, language);
        }
    }

    #[test]
    fn the_accent_round_trips_as_hex_text() {
        let changed = AppSettings {
            accent: AccentColor::parse("#1E90FF").unwrap(),
            ..AppSettings::default()
        };
        let dto = SettingsDto::from(&changed);
        assert_eq!(dto.accent, "#1E90FF");
        assert_eq!(AppSettings::from(&dto).accent, changed.accent);
    }

    #[test]
    fn a_broken_accent_in_the_dto_falls_back_to_the_default() {
        let dto = SettingsDto {
            accent: "not-a-color".into(),
            ..SettingsDto::from(&AppSettings::default())
        };
        assert_eq!(AppSettings::from(&dto).accent, AccentColor::default());
    }
}
