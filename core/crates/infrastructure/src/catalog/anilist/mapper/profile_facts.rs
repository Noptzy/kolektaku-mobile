use domain::media::{FactKind, ProfileFact};

use crate::catalog::anilist::schema::{RawDate, RawProfile};

fn fact(kind: FactKind, value: impl Into<String>) -> Option<ProfileFact> {
    let value = value.into();
    let value = value.trim();
    (!value.is_empty()).then(|| ProfileFact {
        kind,
        value: value.to_string(),
    })
}

pub fn partial_date(date: &RawDate) -> Option<String> {
    match (date.year, date.month, date.day) {
        (Some(year), Some(month), Some(day)) => Some(format!("{year:04}-{month:02}-{day:02}")),
        (Some(year), Some(month), None) => Some(format!("{year:04}-{month:02}")),
        (Some(year), None, _) => Some(format!("{year:04}")),
        (None, Some(month), Some(day)) => Some(format!("--{month:02}-{day:02}")),
        _ => None,
    }
}

fn years_active(years: &[u16]) -> Option<String> {
    match years {
        [] => None,
        [start] => Some(format!("{start}-")),
        [start, end, ..] => Some(format!("{start}-{end}")),
    }
}

fn age_text(value: &serde_json::Value) -> Option<String> {
    match value {
        serde_json::Value::String(text) => Some(text.clone()),
        serde_json::Value::Number(number) => Some(number.to_string()),
        _ => None,
    }
}

fn joined(values: &[String]) -> String {
    values
        .iter()
        .map(|text| text.trim())
        .filter(|text| !text.is_empty())
        .collect::<Vec<_>>()
        .join(", ")
}

pub fn profile_facts(raw: &RawProfile) -> Vec<ProfileFact> {
    let nicknames: Vec<String> = raw
        .name
        .alternative
        .clone()
        .unwrap_or_default()
        .into_iter()
        .filter(|name| Some(name) != raw.name.full.as_ref())
        .collect();
    let favourites = raw.favourites.filter(|count| *count > 0);
    [
        fact(
            FactKind::Occupations,
            joined(&raw.occupations.clone().unwrap_or_default()),
        ),
        raw.date_of_birth
            .as_ref()
            .and_then(partial_date)
            .and_then(|date| fact(FactKind::Birthday, date)),
        raw.date_of_death
            .as_ref()
            .and_then(partial_date)
            .and_then(|date| fact(FactKind::Died, date)),
        raw.age
            .as_ref()
            .and_then(age_text)
            .and_then(|age| fact(FactKind::Age, age)),
        raw.gender
            .clone()
            .and_then(|gender| fact(FactKind::Gender, gender)),
        raw.blood_type
            .clone()
            .and_then(|blood| fact(FactKind::BloodType, blood)),
        raw.home_town
            .clone()
            .and_then(|town| fact(FactKind::HomeTown, town)),
        raw.years_active
            .as_deref()
            .and_then(years_active)
            .and_then(|years| fact(FactKind::YearsActive, years)),
        raw.language
            .clone()
            .and_then(|language| fact(FactKind::Language, language)),
        fact(FactKind::Nicknames, joined(&nicknames)),
        favourites.and_then(|count| fact(FactKind::Favourites, count.to_string())),
    ]
    .into_iter()
    .flatten()
    .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn date(year: Option<u16>, month: Option<u8>, day: Option<u8>) -> RawDate {
        RawDate { year, month, day }
    }

    #[test]
    fn dates_keep_only_the_parts_that_are_known() {
        assert_eq!(
            partial_date(&date(Some(1990), Some(3), Some(9))).as_deref(),
            Some("1990-03-09")
        );
        assert_eq!(
            partial_date(&date(Some(1990), Some(3), None)).as_deref(),
            Some("1990-03")
        );
        assert_eq!(
            partial_date(&date(Some(1990), None, None)).as_deref(),
            Some("1990")
        );
        assert_eq!(
            partial_date(&date(None, Some(3), Some(9))).as_deref(),
            Some("--03-09")
        );
        assert_eq!(partial_date(&date(None, None, None)), None);
        assert_eq!(partial_date(&date(None, Some(3), None)), None);
    }

    #[test]
    fn years_active_is_open_ended_with_one_year() {
        assert_eq!(years_active(&[2004]).as_deref(), Some("2004-"));
        assert_eq!(years_active(&[2004, 2010]).as_deref(), Some("2004-2010"));
        assert_eq!(years_active(&[]), None);
    }

    #[test]
    fn ages_may_be_text_or_numbers() {
        assert_eq!(
            age_text(&serde_json::json!("17-18")).as_deref(),
            Some("17-18")
        );
        assert_eq!(age_text(&serde_json::json!(34)).as_deref(), Some("34"));
        assert_eq!(age_text(&serde_json::json!(null)), None);
    }
}
