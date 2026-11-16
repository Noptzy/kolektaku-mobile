use super::keyed::keyed_enum;

keyed_enum! {
    ReadingSize {
        Smallest => "xs",
        Small => "s",
        Medium => "m",
        Large => "l",
        Largest => "xl",
    } default Medium
}

keyed_enum! {
    ReadingSpacing {
        Tight => "tight",
        Normal => "normal",
        Loose => "loose",
    } default Normal
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_middle_choices_are_the_defaults() {
        assert_eq!(ReadingSize::default(), ReadingSize::Medium);
        assert_eq!(ReadingSpacing::default(), ReadingSpacing::Normal);
    }

    #[test]
    fn every_choice_round_trips_through_its_key() {
        for size in [
            ReadingSize::Smallest,
            ReadingSize::Small,
            ReadingSize::Medium,
            ReadingSize::Large,
            ReadingSize::Largest,
        ] {
            assert_eq!(ReadingSize::parse(size.key()), Some(size));
        }
        for spacing in [
            ReadingSpacing::Tight,
            ReadingSpacing::Normal,
            ReadingSpacing::Loose,
        ] {
            assert_eq!(ReadingSpacing::parse(spacing.key()), Some(spacing));
        }
        assert_eq!(ReadingSize::parse("huge"), None);
    }
}
