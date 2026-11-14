use domain::media::{Discover, DiscoverSort, MediaFormat, MediaOrigin, MediaStatus, YearSpan};
use serde::de::DeserializeOwned;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum DiscoverSortDto {
    #[default]
    Relevance,
    Newest,
    Oldest,
    Az,
    Za,
}

impl From<DiscoverSortDto> for DiscoverSort {
    fn from(sort: DiscoverSortDto) -> Self {
        match sort {
            DiscoverSortDto::Relevance => Self::Relevance,
            DiscoverSortDto::Newest => Self::Newest,
            DiscoverSortDto::Oldest => Self::Oldest,
            DiscoverSortDto::Az => Self::TitleAz,
            DiscoverSortDto::Za => Self::TitleZa,
        }
    }
}

#[derive(Debug, Clone, Default)]
pub struct DiscoverFilterDto {
    pub query: Option<String>,
    pub genre: Option<String>,
    pub year_from: Option<u16>,
    pub year_to: Option<u16>,
    pub formats: Vec<String>,
    pub status: Option<String>,
    pub origin: Option<String>,
    pub sort: DiscoverSortDto,
}

fn catalog_name<T: DeserializeOwned>(name: &str) -> Option<T> {
    serde_json::from_value(serde_json::Value::String(name.trim().to_uppercase())).ok()
}

impl From<DiscoverFilterDto> for Discover {
    fn from(filter: DiscoverFilterDto) -> Self {
        let years = (filter.year_from.is_some() || filter.year_to.is_some()).then_some(YearSpan {
            from: filter.year_from,
            to: filter.year_to,
        });
        Self {
            query: filter.query,
            genre: filter.genre,
            years,
            formats: filter
                .formats
                .iter()
                .filter_map(|name| catalog_name::<MediaFormat>(name))
                .collect(),
            status: filter
                .status
                .as_deref()
                .and_then(catalog_name::<MediaStatus>),
            origin: filter
                .origin
                .as_deref()
                .and_then(catalog_name::<MediaOrigin>),
            sort: filter.sort.into(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_sort_maps_to_its_own() {
        assert_eq!(
            DiscoverSort::from(DiscoverSortDto::Relevance),
            DiscoverSort::Relevance
        );
        assert_eq!(
            DiscoverSort::from(DiscoverSortDto::Newest),
            DiscoverSort::Newest
        );
        assert_eq!(
            DiscoverSort::from(DiscoverSortDto::Oldest),
            DiscoverSort::Oldest
        );
        assert_eq!(
            DiscoverSort::from(DiscoverSortDto::Az),
            DiscoverSort::TitleAz
        );
        assert_eq!(
            DiscoverSort::from(DiscoverSortDto::Za),
            DiscoverSort::TitleZa
        );
    }

    fn filter(edit: impl FnOnce(&mut DiscoverFilterDto)) -> Discover {
        let mut dto = DiscoverFilterDto::default();
        edit(&mut dto);
        dto.into()
    }

    #[test]
    fn no_year_means_no_span() {
        let found = filter(|dto| {
            dto.genre = Some("Action".into());
            dto.sort = DiscoverSortDto::Newest;
        });
        assert!(found.years.is_none());
        assert_eq!(found.genre.as_deref(), Some("Action"));
        assert_eq!(found.sort, DiscoverSort::Newest);
    }

    #[test]
    fn either_end_makes_a_span() {
        let one = filter(|dto| {
            dto.year_from = Some(2015);
            dto.year_to = Some(2015);
        });
        assert_eq!(one.years, Some(YearSpan::only(2015)));
        let older = filter(|dto| dto.year_to = Some(2014));
        assert_eq!(older.years, Some(YearSpan::up_to(2014)));
    }

    #[test]
    fn the_text_travels_with_the_filter() {
        let found = filter(|dto| dto.query = Some("kimi".into()));
        assert_eq!(found.query.as_deref(), Some("kimi"));
    }

    #[test]
    fn facet_names_become_catalog_values_and_bad_ones_are_dropped() {
        let found = filter(|dto| {
            dto.formats = vec!["tv".into(), "TV_SHORT".into(), "nonsense".into()];
            dto.status = Some("Releasing".into());
            dto.origin = Some("light_novel".into());
        });
        assert_eq!(found.formats, vec![MediaFormat::Tv, MediaFormat::TvShort]);
        assert_eq!(found.status, Some(MediaStatus::Releasing));
        assert_eq!(found.origin, Some(MediaOrigin::LightNovel));
    }

    #[test]
    fn an_unknown_status_or_origin_means_no_filter() {
        let found = filter(|dto| {
            dto.status = Some("whenever".into());
            dto.origin = Some(String::new());
        });
        assert_eq!(found.status, None);
        assert_eq!(found.origin, None);
    }
}
