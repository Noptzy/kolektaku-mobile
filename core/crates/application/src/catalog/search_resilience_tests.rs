use domain::error::SourceError;
use domain::media::MediaKind;

use super::search_test_support::{anime, harness, item, source};
use crate::testing::FakeCatalog;

fn catalog() -> FakeCatalog {
    FakeCatalog::new()
}

#[tokio::test]
async fn anilist_rate_limiting_does_not_empty_the_list() {
    let limited = catalog().failing_with(SourceError::RateLimited {
        retry_after_secs: Some(30),
    });
    let h = harness(
        limited,
        vec![source("a").with_search("naruto", vec![item("1/naruto", "Naruto")])],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    assert_eq!(outcome.cards[0].title, "Naruto");
    assert!(outcome.cards[0].summary.is_none());
    assert_eq!(outcome.notices.len(), 1);
    assert!(outcome.notices[0].origin.is_none());
    assert!(matches!(
        outcome.notices[0].error,
        SourceError::RateLimited { .. }
    ));
}

#[tokio::test]
async fn a_failing_site_does_not_hide_the_others() {
    let h = harness(
        catalog().with_search(MediaKind::Anime, "naruto", vec![anime(20, "Naruto", &[])]),
        vec![
            source("a").failing_with(SourceError::Unavailable("down".into())),
            source("b").with_search("naruto", vec![item("naruto", "Naruto")]),
        ],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    assert_eq!(outcome.cards[0].links.len(), 1);
    assert_eq!(outcome.notices.len(), 1);
    assert_eq!(
        outcome.notices[0].origin.as_ref().map(|id| id.as_str()),
        Some("a")
    );
}

#[tokio::test]
async fn when_everything_fails_the_first_error_is_reported() {
    let h = harness(
        catalog().failing_with(SourceError::Network("offline".into())),
        vec![source("a").failing_with(SourceError::Unavailable("down".into()))],
    );
    let error = h
        .use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::Network("offline".into()));
}

#[tokio::test]
async fn every_source_and_the_catalog_are_asked_exactly_once_when_there_are_results() {
    let h = harness(
        catalog().with_search(MediaKind::Anime, "naruto", vec![anime(20, "Naruto", &[])]),
        vec![source("a").with_search("naruto", vec![item("1/naruto", "Naruto")])],
    );
    h.use_case
        .execute(MediaKind::Anime, "naruto", 1)
        .await
        .unwrap();
    assert_eq!(h.catalog.calls(), vec!["search anime naruto"]);
    assert_eq!(h.sources[0].calls(), vec!["search naruto"]);
}

#[tokio::test]
async fn a_misspelled_keyword_is_retried_in_a_relaxed_form_and_reranked_locally() {
    let film = anime(21519, "Kimi no Na wa.", &["Your Name."]);
    let noise = anime(4, "Kimi no Suizou wo Tabetai", &[]);
    let h = harness(
        catalog().with_search(MediaKind::Anime, "kimi no", vec![noise.clone(), film]),
        vec![source("a").with_search(
            "kimi no",
            vec![
                item("4/suizou", "Kimi no Suizou wo Tabetai"),
                item("1020/kimi-no-na-wa", "Kimi no Na wa."),
            ],
        )],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "kimi no nawa", 1)
        .await
        .unwrap();
    assert_eq!(outcome.cards.len(), 1);
    assert_eq!(outcome.cards[0].title, "Kimi no Na wa.");
    assert_eq!(
        outcome.cards[0].links[0].item.as_str(),
        "1020/kimi-no-na-wa"
    );
    assert_eq!(
        h.catalog.calls(),
        vec!["search anime kimi no nawa", "search anime kimi no"]
    );
    assert_eq!(
        h.sources[0].calls(),
        vec!["search kimi no nawa", "search kimi no"]
    );
}

#[tokio::test]
async fn relaxing_never_costs_more_than_two_extra_requests_per_source() {
    let h = harness(catalog(), vec![source("a")]);
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "kimetsu no yaiba yuukaku hen", 1)
        .await
        .unwrap();
    assert!(outcome.cards.is_empty());
    assert_eq!(h.catalog.calls().len(), 3);
    assert_eq!(h.sources[0].calls().len(), 3);
}

#[tokio::test]
async fn a_failing_participant_is_not_retried() {
    let h = harness(
        catalog().failing_with(SourceError::RateLimited {
            retry_after_secs: None,
        }),
        vec![source("a")],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "kimi no nawa", 1)
        .await
        .unwrap();
    assert!(outcome.cards.is_empty());
    assert_eq!(h.catalog.calls().len(), 1);
    assert_eq!(h.sources[0].calls().len(), 2);
}

#[tokio::test]
async fn relaxed_results_that_do_not_resemble_the_keyword_are_dropped() {
    let h = harness(
        catalog(),
        vec![source("a").with_search(
            "kimi no",
            vec![item("4/suizou", "Kimi no Suizou wo Tabetai")],
        )],
    );
    let outcome = h
        .use_case
        .execute(MediaKind::Anime, "kimi no nawa", 1)
        .await
        .unwrap();
    assert!(outcome.cards.is_empty());
}
