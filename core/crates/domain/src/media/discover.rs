use serde::{Deserialize, Serialize};

use super::{MediaFormat, MediaOrigin, MediaStatus};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
pub enum DiscoverSort {
    #[default]
    Relevance,
    Newest,
    Oldest,
    TitleAz,
    TitleZa,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct YearSpan {
    pub from: Option<u16>,
    pub to: Option<u16>,
}

impl YearSpan {
    pub fn only(year: u16) -> Self {
        Self {
            from: Some(year),
            to: Some(year),
        }
    }

    pub fn up_to(year: u16) -> Self {
        Self {
            from: None,
            to: Some(year),
        }
    }

    pub fn contains(&self, year: u16) -> bool {
        self.from.is_none_or(|from| year >= from) && self.to.is_none_or(|to| year <= to)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
pub struct Discover {
    pub query: Option<String>,
    pub genre: Option<String>,
    pub years: Option<YearSpan>,
    pub formats: Vec<MediaFormat>,
    pub status: Option<MediaStatus>,
    pub origin: Option<MediaOrigin>,
    pub sort: DiscoverSort,
}

impl Discover {
    pub fn searching(query: impl Into<String>) -> Self {
        Self {
            query: Some(query.into()),
            ..Self::default()
        }
    }

    pub fn in_genre(genre: impl Into<String>) -> Self {
        Self {
            genre: Some(genre.into()),
            ..Self::default()
        }
    }

    pub fn within(mut self, years: YearSpan) -> Self {
        self.years = Some(years);
        self
    }

    pub fn in_formats(mut self, formats: Vec<MediaFormat>) -> Self {
        self.formats = formats;
        self
    }

    pub fn with_status(mut self, status: MediaStatus) -> Self {
        self.status = Some(status);
        self
    }

    pub fn adapted_from(mut self, origin: MediaOrigin) -> Self {
        self.origin = Some(origin);
        self
    }

    pub fn sorted(mut self, sort: DiscoverSort) -> Self {
        self.sort = sort;
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_single_year_contains_only_itself() {
        let span = YearSpan::only(2020);
        assert!(span.contains(2020));
        assert!(!span.contains(2019));
        assert!(!span.contains(2021));
    }

    #[test]
    fn an_open_start_reaches_back_forever() {
        let span = YearSpan::up_to(2014);
        assert!(span.contains(1980));
        assert!(span.contains(2014));
        assert!(!span.contains(2015));
    }

    #[test]
    fn the_default_asks_for_nothing_in_particular() {
        let filter = Discover::default();
        assert!(filter.query.is_none() && filter.genre.is_none() && filter.years.is_none());
        assert!(filter.formats.is_empty() && filter.status.is_none() && filter.origin.is_none());
        assert_eq!(filter.sort, DiscoverSort::Relevance);
    }

    #[test]
    fn builders_set_one_field_each() {
        let filter = Discover::searching("naruto")
            .within(YearSpan::only(2002))
            .sorted(DiscoverSort::Newest);
        assert_eq!(filter.query.as_deref(), Some("naruto"));
        assert_eq!(filter.years, Some(YearSpan::only(2002)));
        assert_eq!(filter.sort, DiscoverSort::Newest);
        assert_eq!(
            Discover::in_genre("Action").genre.as_deref(),
            Some("Action")
        );
    }

    #[test]
    fn the_new_filters_are_set_by_their_own_builders() {
        let filter = Discover::searching("ghibli")
            .in_formats(vec![MediaFormat::Movie])
            .with_status(MediaStatus::Finished)
            .adapted_from(MediaOrigin::Manga);
        assert_eq!(filter.formats, vec![MediaFormat::Movie]);
        assert_eq!(filter.status, Some(MediaStatus::Finished));
        assert_eq!(filter.origin, Some(MediaOrigin::Manga));
    }

    #[test]
    fn a_filter_survives_json() {
        let filter = Discover::in_genre("Drama")
            .within(YearSpan::up_to(2010))
            .in_formats(vec![MediaFormat::Tv, MediaFormat::TvShort])
            .with_status(MediaStatus::Releasing)
            .adapted_from(MediaOrigin::Original);
        let json = serde_json::to_string(&filter).unwrap();
        assert_eq!(serde_json::from_str::<Discover>(&json).unwrap(), filter);
    }
}
