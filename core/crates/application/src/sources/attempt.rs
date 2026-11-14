use std::future::Future;

use domain::error::SourceError;
use domain::media::MediaRef;
use domain::source::{SourceId, SourceLink, SourceLinkStore, Unit};

use super::{SourceDirectory, SourceHealth, rank_links};

const SAME_UNIT_TOLERANCE: f64 = 1e-9;

pub fn find_unit(units: &[Unit], number: f64) -> Option<&Unit> {
    units
        .iter()
        .find(|unit| (unit.number - number).abs() < SAME_UNIT_TOLERANCE)
}

pub async fn candidate_links<S: SourceLinkStore>(
    store: &S,
    directory: &SourceDirectory,
    health: &SourceHealth,
    reference: &MediaRef,
) -> Vec<SourceLink> {
    let stored = store.links_for(reference).await.unwrap_or_default();
    let known: Vec<SourceLink> = stored
        .into_iter()
        .filter(|link| directory.get(&link.source).is_ok())
        .collect();
    if known.is_empty()
        && let MediaRef::Source { source, item } = reference
    {
        return vec![SourceLink::chosen_by_user(source.clone(), item.clone(), 0)];
    }
    rank_links(
        known,
        &directory.priorities(),
        health,
        directory.preferred().as_ref(),
    )
}

#[derive(Debug)]
pub struct Working<T> {
    pub link: SourceLink,
    pub value: T,
    pub switched_from: Option<SourceId>,
}

pub async fn first_working<T, F, Fut>(
    links: Vec<SourceLink>,
    health: &SourceHealth,
    preferred: Option<&SourceId>,
    exclude: &[SourceId],
    mut attempt: F,
) -> Result<Working<T>, SourceError>
where
    F: FnMut(SourceLink) -> Fut,
    Fut: Future<Output = Result<T, SourceError>>,
{
    let mut ordered = links;
    if let Some(wanted) = preferred {
        ordered.sort_by_key(|link| link.source != *wanted);
    }
    let mut first_tried: Option<SourceId> = None;
    let mut last_error: Option<SourceError> = None;
    for link in ordered {
        let forced = preferred == Some(&link.source);
        if exclude.contains(&link.source) || (health.is_skipped(&link.source) && !forced) {
            continue;
        }
        let source = link.source.clone();
        first_tried.get_or_insert_with(|| source.clone());
        match attempt(link.clone()).await {
            Ok(value) => {
                health.record_success(&source);
                let switched_from = first_tried.filter(|first| *first != source);
                return Ok(Working {
                    link,
                    value,
                    switched_from,
                });
            }
            Err(error) => {
                health.record_failure(&source, &error);
                last_error = Some(error);
            }
        }
    }
    Err(last_error.unwrap_or_else(|| SourceError::NotFound("no source has this".into())))
}

#[cfg(test)]
mod tests {
    use std::sync::Arc;

    use domain::matching::Confidence;
    use domain::source::ItemId;

    use super::*;
    use crate::testing::FakeClock;

    fn link(source: &str) -> SourceLink {
        SourceLink::matched(
            SourceId::new(source),
            ItemId::new("x"),
            Confidence::new(0.9),
            0,
        )
    }

    fn health() -> SourceHealth {
        SourceHealth::new(Arc::new(FakeClock::at(0)))
    }

    async fn run(
        links: Vec<SourceLink>,
        preferred: Option<&SourceId>,
        exclude: &[SourceId],
        failing: &[&str],
    ) -> Result<Working<String>, SourceError> {
        let health = health();
        first_working(links, &health, preferred, exclude, |link| {
            let broken = failing.contains(&link.source.as_str());
            async move {
                if broken {
                    Err(SourceError::Unavailable(link.source.to_string()))
                } else {
                    Ok(link.source.to_string())
                }
            }
        })
        .await
    }

    #[tokio::test]
    async fn the_first_link_that_works_wins_without_a_switch_notice() {
        let working = run(vec![link("a"), link("b")], None, &[], &[])
            .await
            .unwrap();
        assert_eq!((working.value.as_str(), working.switched_from), ("a", None));
    }

    #[tokio::test]
    async fn a_failing_first_link_hands_over_to_the_next_and_says_so() {
        let working = run(vec![link("a"), link("b")], None, &[], &["a"])
            .await
            .unwrap();
        assert_eq!(working.value, "b");
        assert_eq!(working.switched_from, Some(SourceId::new("a")));
    }

    #[tokio::test]
    async fn the_preferred_site_goes_first_and_excluded_sites_are_never_tried() {
        let preferred = SourceId::new("b");
        let working = run(vec![link("a"), link("b")], Some(&preferred), &[], &[])
            .await
            .unwrap();
        assert_eq!(working.value, "b");
        let skipping = run(vec![link("a"), link("b")], None, &[SourceId::new("a")], &[])
            .await
            .unwrap();
        assert_eq!(skipping.value, "b");
        assert_eq!(skipping.switched_from, None);
    }

    #[tokio::test]
    async fn when_every_link_fails_the_last_error_comes_back() {
        let error = run(vec![link("a"), link("b")], None, &[], &["a", "b"])
            .await
            .unwrap_err();
        assert_eq!(error, SourceError::Unavailable("b".into()));
    }

    #[tokio::test]
    async fn no_links_means_not_found() {
        assert!(matches!(
            run(vec![], None, &[], &[]).await,
            Err(SourceError::NotFound(_))
        ));
    }

    #[test]
    fn units_are_found_by_number_including_fractions() {
        let units = vec![Unit::new("a", 1.0, "1"), Unit::new("b", 1.5, "1.5")];
        assert_eq!(
            find_unit(&units, 1.5).map(|unit| unit.id.as_str()),
            Some("b")
        );
        assert!(find_unit(&units, 2.0).is_none());
    }
}
