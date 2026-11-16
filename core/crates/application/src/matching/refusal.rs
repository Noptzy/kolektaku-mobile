use domain::media::MediaStatus;

use super::family::{FormatFamily, family_of_format, family_of_type};
use super::target::{CandidateFacts, MatchTarget};

pub const MAX_FILM_UNITS: u32 = 3;
pub const MAX_YEAR_GAP_FINISHED: u16 = 1;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Refusal {
    TargetNotReleased,
    DifferentFormat,
    FilmWithManyUnits,
    YearTooFar,
}

impl Refusal {
    pub fn reason(self) -> &'static str {
        match self {
            Refusal::TargetNotReleased => "belum tayang",
            Refusal::DifferentFormat => "format beda",
            Refusal::FilmWithManyUnits => "movie vs banyak unit",
            Refusal::YearTooFar => "tahun terlalu jauh",
        }
    }
}

fn year_too_far(target: &MatchTarget, facts: &CandidateFacts) -> bool {
    let finished = target.status == Some(MediaStatus::Finished);
    match (target.year, facts.year) {
        (Some(wanted), Some(actual)) => finished && wanted.abs_diff(actual) > MAX_YEAR_GAP_FINISHED,
        _ => false,
    }
}

pub fn refusal_of(target: &MatchTarget, facts: &CandidateFacts) -> Option<Refusal> {
    if target.status == Some(MediaStatus::NotYetReleased) {
        return Some(Refusal::TargetNotReleased);
    }
    let wanted = family_of_format(target.format);
    let actual = family_of_type(facts.type_text.as_deref());
    if let (Some(wanted), Some(actual)) = (wanted, actual)
        && wanted != actual
    {
        return Some(Refusal::DifferentFormat);
    }
    let many_units = facts.unit_count.is_some_and(|units| units > MAX_FILM_UNITS);
    if wanted == Some(FormatFamily::Movie) && many_units {
        return Some(Refusal::FilmWithManyUnits);
    }
    year_too_far(target, facts).then_some(Refusal::YearTooFar)
}

#[cfg(test)]
mod tests {
    use super::*;
    use domain::media::MediaFormat;

    fn target(format: MediaFormat, status: MediaStatus) -> MatchTarget {
        MatchTarget {
            titles: vec!["Show".into()],
            format: Some(format),
            year: Some(2024),
            unit_count: None,
            status: Some(status),
        }
    }

    fn facts(type_text: &str, year: Option<u16>, units: Option<u32>) -> CandidateFacts {
        CandidateFacts {
            titles: vec!["Show".into()],
            type_text: Some(type_text.into()),
            year,
            unit_count: units,
        }
    }

    #[test]
    fn a_title_that_has_not_aired_is_never_linked_by_name() {
        let wanted = target(MediaFormat::Movie, MediaStatus::NotYetReleased);
        let found = facts("Movie", Some(2020), Some(1));
        assert_eq!(
            refusal_of(&wanted, &found),
            Some(Refusal::TargetNotReleased)
        );
    }

    #[test]
    fn another_format_family_is_refused() {
        let wanted = target(MediaFormat::Movie, MediaStatus::Finished);
        let found = facts("TV", Some(2024), Some(1));
        assert_eq!(refusal_of(&wanted, &found), Some(Refusal::DifferentFormat));
    }

    #[test]
    fn a_film_is_not_a_series_with_many_episodes() {
        let wanted = target(MediaFormat::Movie, MediaStatus::Finished);
        let found = facts("Movie", Some(2024), Some(11));
        assert_eq!(
            refusal_of(&wanted, &found),
            Some(Refusal::FilmWithManyUnits)
        );
        let single = facts("Movie", Some(2024), Some(1));
        assert_eq!(refusal_of(&wanted, &single), None);
    }

    #[test]
    fn a_finished_title_needs_a_year_within_one() {
        let wanted = target(MediaFormat::Tv, MediaStatus::Finished);
        assert_eq!(
            refusal_of(&wanted, &facts("TV", Some(2021), None)),
            Some(Refusal::YearTooFar)
        );
        assert_eq!(refusal_of(&wanted, &facts("TV", Some(2023), None)), None);
        assert_eq!(refusal_of(&wanted, &facts("TV", None, None)), None);
    }

    #[test]
    fn a_running_title_ignores_the_year_gap() {
        let wanted = target(MediaFormat::Tv, MediaStatus::Releasing);
        assert_eq!(refusal_of(&wanted, &facts("TV", Some(2015), None)), None);
    }

    #[test]
    fn every_refusal_has_a_reason() {
        for refusal in [
            Refusal::TargetNotReleased,
            Refusal::DifferentFormat,
            Refusal::FilmWithManyUnits,
            Refusal::YearTooFar,
        ] {
            assert!(!refusal.reason().is_empty());
        }
    }
}
