use super::keyed::keyed_enum;

keyed_enum! {
    QualityPreference {
        Auto => "auto",
        P1080 => "1080",
        P720 => "720",
        P480 => "480",
        P360 => "360",
    } default Auto
}

impl QualityPreference {
    pub fn max_height(self) -> Option<u32> {
        match self {
            Self::Auto => None,
            Self::P1080 => Some(1080),
            Self::P720 => Some(720),
            Self::P480 => Some(480),
            Self::P360 => Some(360),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn auto_has_no_ceiling_and_the_others_name_their_height() {
        assert_eq!(QualityPreference::Auto.max_height(), None);
        assert_eq!(QualityPreference::P1080.max_height(), Some(1080));
        assert_eq!(QualityPreference::P360.max_height(), Some(360));
    }

    #[test]
    fn keys_round_trip_and_default_is_auto() {
        for quality in [
            QualityPreference::Auto,
            QualityPreference::P1080,
            QualityPreference::P720,
            QualityPreference::P480,
            QualityPreference::P360,
        ] {
            assert_eq!(QualityPreference::parse(quality.key()), Some(quality));
        }
        assert_eq!(QualityPreference::default(), QualityPreference::Auto);
        assert_eq!(QualityPreference::parse("4k"), None);
    }
}
