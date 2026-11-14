use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{Discover, MediaId, MediaKind, MediaSummary, MediaTitle, YearSpan};

use super::DiscoverMedia;
use crate::testing::{FakeCatalog, FakeClock};

fn summary(id: u64, title: &str) -> MediaSummary {
    MediaSummary::new(
        MediaId::new(id).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(title),
    )
}

fn discover_over(catalog: Arc<FakeCatalog>) -> DiscoverMedia<FakeCatalog> {
    DiscoverMedia::new(catalog, Arc::new(FakeClock::at(1_000)))
}

#[tokio::test]
async fn the_catalog_page_becomes_cards_in_order() {
    let catalog =
        Arc::new(FakeCatalog::new().with_discovered(vec![summary(1, "Satu"), summary(2, "Dua")]));
    let outcome = discover_over(catalog)
        .execute(MediaKind::Anime, &Discover::in_genre("Action"), 1)
        .await
        .unwrap();
    let titles: Vec<&str> = outcome
        .cards
        .iter()
        .map(|card| card.title.as_str())
        .collect();
    assert_eq!(titles, vec!["Satu", "Dua"]);
    assert!(outcome.notices.is_empty());
    assert!(!outcome.has_next_page);
}

#[tokio::test]
async fn the_filter_and_the_page_reach_the_catalog_untouched() {
    let catalog = Arc::new(FakeCatalog::new());
    let filter = Discover::searching("naruto").within(YearSpan::only(2002));
    discover_over(catalog.clone())
        .execute(MediaKind::Manga, &filter, 3)
        .await
        .unwrap();
    let calls = catalog.calls();
    assert_eq!(calls.len(), 1);
    assert!(calls[0].starts_with("discover manga"));
    assert!(calls[0].contains("naruto"));
    assert!(calls[0].contains("2002"));
    assert!(calls[0].ends_with(" 3"));
}

#[tokio::test]
async fn nothing_found_is_an_empty_page_and_not_an_error() {
    let outcome = discover_over(Arc::new(FakeCatalog::new()))
        .execute(MediaKind::Anime, &Discover::default(), 1)
        .await
        .unwrap();
    assert!(outcome.cards.is_empty());
}

#[tokio::test]
async fn a_catalog_failure_reaches_the_caller() {
    let catalog = Arc::new(FakeCatalog::new().failing_with(SourceError::Network("down".into())));
    let result = discover_over(catalog)
        .execute(MediaKind::Anime, &Discover::default(), 1)
        .await;
    assert!(matches!(result, Err(SourceError::Network(_))));
}
