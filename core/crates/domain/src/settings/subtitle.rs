use super::keyed::keyed_enum;

keyed_enum! {
    SubtitleLanguage {
        Indonesian => "id",
        English => "en",
        Off => "off",
    } default Indonesian
}

keyed_enum! {
    SubtitleSize {
        Small => "small",
        Medium => "medium",
        Large => "large",
        Huge => "huge",
    } default Medium
}

keyed_enum! {
    SubtitleColor {
        White => "white",
        Yellow => "yellow",
        Green => "green",
        Cyan => "cyan",
        Pink => "pink",
    } default White
}

keyed_enum! {
    SubtitleEdge {
        None => "none",
        Shadow => "shadow",
        Outline => "outline",
    } default Outline
}

keyed_enum! {
    SubtitleBoxColor {
        Black => "black",
        Gray => "gray",
        Navy => "navy",
    } default Black
}

keyed_enum! {
    SubtitleBoxOpacity {
        Off => "off",
        Light => "light",
        Medium => "medium",
        Full => "full",
    } default Off
}

impl SubtitleSize {
    pub fn scale(self) -> f32 {
        match self {
            Self::Small => 0.85,
            Self::Medium => 1.0,
            Self::Large => 1.3,
            Self::Huge => 1.65,
        }
    }
}

impl SubtitleBoxOpacity {
    pub fn fraction(self) -> f32 {
        match self {
            Self::Off => 0.0,
            Self::Light => 0.4,
            Self::Medium => 0.7,
            Self::Full => 1.0,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_value_survives_its_key() {
        for language in [
            SubtitleLanguage::Indonesian,
            SubtitleLanguage::English,
            SubtitleLanguage::Off,
        ] {
            assert_eq!(SubtitleLanguage::parse(language.key()), Some(language));
        }
        for size in [
            SubtitleSize::Small,
            SubtitleSize::Medium,
            SubtitleSize::Large,
            SubtitleSize::Huge,
        ] {
            assert_eq!(SubtitleSize::parse(size.key()), Some(size));
        }
        for color in [
            SubtitleColor::White,
            SubtitleColor::Yellow,
            SubtitleColor::Green,
            SubtitleColor::Cyan,
            SubtitleColor::Pink,
        ] {
            assert_eq!(SubtitleColor::parse(color.key()), Some(color));
        }
        for edge in [
            SubtitleEdge::None,
            SubtitleEdge::Shadow,
            SubtitleEdge::Outline,
        ] {
            assert_eq!(SubtitleEdge::parse(edge.key()), Some(edge));
        }
        for color in [
            SubtitleBoxColor::Black,
            SubtitleBoxColor::Gray,
            SubtitleBoxColor::Navy,
        ] {
            assert_eq!(SubtitleBoxColor::parse(color.key()), Some(color));
        }
        for opacity in [
            SubtitleBoxOpacity::Off,
            SubtitleBoxOpacity::Light,
            SubtitleBoxOpacity::Medium,
            SubtitleBoxOpacity::Full,
        ] {
            assert_eq!(SubtitleBoxOpacity::parse(opacity.key()), Some(opacity));
        }
    }

    #[test]
    fn unknown_keys_are_not_guessed() {
        assert_eq!(SubtitleLanguage::parse("fr"), None);
        assert_eq!(SubtitleSize::parse(""), None);
        assert_eq!(SubtitleEdge::parse("BOX"), None);
        assert_eq!(SubtitleColor::parse("purple"), None);
    }

    #[test]
    fn the_defaults_are_white_text_with_a_dark_outline_and_no_box() {
        assert_eq!(SubtitleLanguage::default(), SubtitleLanguage::Indonesian);
        assert_eq!(SubtitleSize::default(), SubtitleSize::Medium);
        assert_eq!(SubtitleColor::default(), SubtitleColor::White);
        assert_eq!(SubtitleEdge::default(), SubtitleEdge::Outline);
        assert_eq!(SubtitleBoxColor::default(), SubtitleBoxColor::Black);
        assert_eq!(SubtitleBoxOpacity::default(), SubtitleBoxOpacity::Off);
    }

    #[test]
    fn larger_sizes_scale_up() {
        assert!(SubtitleSize::Small.scale() < SubtitleSize::Medium.scale());
        assert!(SubtitleSize::Medium.scale() < SubtitleSize::Large.scale());
        assert!(SubtitleSize::Large.scale() < SubtitleSize::Huge.scale());
    }

    #[test]
    fn the_box_gets_more_solid_step_by_step() {
        let steps = [
            SubtitleBoxOpacity::Off,
            SubtitleBoxOpacity::Light,
            SubtitleBoxOpacity::Medium,
            SubtitleBoxOpacity::Full,
        ];
        assert!(
            steps
                .windows(2)
                .all(|pair| pair[0].fraction() < pair[1].fraction())
        );
        assert_eq!(SubtitleBoxOpacity::Off.fraction(), 0.0);
        assert_eq!(SubtitleBoxOpacity::Full.fraction(), 1.0);
    }
}
