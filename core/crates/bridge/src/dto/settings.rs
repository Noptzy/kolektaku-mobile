use domain::settings::{
    AppSettings, QualityPreference, SubtitleBoxColor, SubtitleBoxOpacity, SubtitleColor,
    SubtitleEdge, SubtitleLanguage, SubtitleSize,
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
        };
        let dto = SettingsDto::from(&changed);
        assert_eq!(dto.anime_source.as_deref(), Some("x"));
        assert_eq!(dto.quality, QualityDto::P360);
        assert_eq!(AppSettings::from(&dto), changed);
    }
}
