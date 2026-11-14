use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaKind, MediaListKind};

use super::search_test_support::{anime, item, source};
use super::{HomeFeed, HomeSectionId};
use crate::ports::SourceProvider;
use crate::testing::{FakeCatalog, FakeClock, FakeSource};

fn feed(
    catalog: FakeCatalog,
    sources: Vec<FakeSource>,
) -> (HomeFeed<FakeCatalog>, Vec<Arc<FakeSource>>) {
    let sources: Vec<Arc<FakeSource>> = sources.into_iter().map(Arc::new).collect();
    let providers: Vec<Arc<dyn SourceProvider>> = sources
        .iter()
        .map(|source| source.clone() as Arc<dyn SourceProvider>)
        .collect();
    (
        HomeFeed::new(Arc::new(catalog), providers, Arc::new(FakeClock::at(7))),
        sources,
    )
}

fn full_catalog() -> FakeCatalog {
    FakeCatalog::new()
        .with_list(
            MediaKind::Anime,
            MediaListKind::Trending,
            vec![anime(1, "Alpha", &[]), anime(2, "Beta", &[])],
        )
        .with_list(
            MediaKind::Anime,
            MediaListKind::Seasonal,
            vec![anime(3, "Gamma", &[])],
        )
        .with_list(
            MediaKind::Anime,
            MediaListKind::Popular,
            vec![anime(4, "Delta", &[])],
        )
        .with_candidates(MediaKind::Anime, "Alpha", vec![anime(1, "Alpha", &[])])
}

fn ids(outcome: &super::HomeOutcome) -> Vec<HomeSectionId> {
    outcome.sections.iter().map(|section| section.id).collect()
}

#[tokio::test]
async fn an_anime_home_has_trending_seasonal_popular_and_latest_sections() {
    let (feed, _) = feed(
        full_catalog(),
        vec![source("a").with_latest(vec![item("1/alpha", "Alpha")])],
    );
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    assert_eq!(
        ids(&outcome),
        vec![
            HomeSectionId::Trending,
            HomeSectionId::Seasonal,
            HomeSectionId::Popular,
            HomeSectionId::Latest
        ]
    );
    assert_eq!(outcome.sections[0].cards.len(), 2);
    assert!(outcome.notices.is_empty());
}

#[tokio::test]
async fn the_latest_section_links_site_items_to_catalog_entries() {
    let (feed, _) = feed(
        full_catalog(),
        vec![source("a").with_latest(vec![
            item("1/alpha", "Alpha"),
            item("9/mystery", "Mystery Show"),
        ])],
    );
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    let latest = outcome
        .sections
        .iter()
        .find(|section| section.id == HomeSectionId::Latest)
        .unwrap();
    assert_eq!(latest.cards.len(), 2);
    assert!(latest.cards[0].summary.is_some() && latest.cards[0].links.len() == 1);
    assert!(latest.cards[1].summary.is_none());
    assert_eq!(latest.cards[1].title, "Mystery Show");
}

#[tokio::test]
async fn manga_has_no_seasonal_section() {
    let catalog = FakeCatalog::new()
        .with_list(
            MediaKind::Manga,
            MediaListKind::Trending,
            vec![anime(1, "Alpha", &[])],
        )
        .with_list(
            MediaKind::Manga,
            MediaListKind::Popular,
            vec![anime(2, "Beta", &[])],
        );
    let (feed, _) = feed(catalog, vec![]);
    let outcome = feed.execute(MediaKind::Manga).await.unwrap();
    assert_eq!(
        ids(&outcome),
        vec![HomeSectionId::Trending, HomeSectionId::Popular]
    );
}

#[tokio::test]
async fn when_the_catalog_is_down_the_site_latest_still_shows() {
    let catalog = full_catalog().failing_with(SourceError::RateLimited {
        retry_after_secs: Some(30),
    });
    let (feed, _) = feed(
        catalog,
        vec![source("a").with_latest(vec![item("1/alpha", "Alpha")])],
    );
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    assert_eq!(ids(&outcome), vec![HomeSectionId::Latest]);
    assert_eq!(outcome.sections[0].cards[0].title, "Alpha");
    assert!(outcome.sections[0].cards[0].summary.is_none());
    assert!(!outcome.notices.is_empty());
}

#[tokio::test]
async fn when_the_sites_are_down_the_catalog_lists_still_show() {
    let broken = source("a").failing_with(SourceError::Unavailable("down".into()));
    let (feed, _) = feed(full_catalog(), vec![broken]);
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    assert_eq!(
        ids(&outcome),
        vec![
            HomeSectionId::Trending,
            HomeSectionId::Seasonal,
            HomeSectionId::Popular
        ]
    );
    assert_eq!(outcome.notices.len(), 1);
    assert_eq!(
        outcome.notices[0].origin.as_ref().map(|id| id.as_str()),
        Some("a")
    );
}

#[tokio::test]
async fn when_nothing_answers_the_first_error_is_reported() {
    let catalog = full_catalog().failing_with(SourceError::Network("offline".into()));
    let (feed, _) = feed(
        catalog,
        vec![source("a").failing_with(SourceError::Unavailable("down".into()))],
    );
    let error = feed.execute(MediaKind::Anime).await.unwrap_err();
    assert!(matches!(
        error,
        SourceError::Network(_) | SourceError::Unavailable(_)
    ));
}

#[tokio::test]
async fn a_failing_title_match_leaves_site_only_cards_and_a_notice() {
    let (feed, sources) = feed(
        FakeCatalog::new().with_list(
            MediaKind::Anime,
            MediaListKind::Trending,
            vec![anime(1, "Alpha", &[])],
        ),
        vec![source("a").with_latest(vec![item("1/alpha", "Alpha")])],
    );
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    let latest = outcome
        .sections
        .iter()
        .find(|section| section.id == HomeSectionId::Latest)
        .unwrap();
    assert!(latest.cards[0].summary.is_none());
    assert_eq!(sources[0].calls(), vec!["latest 1"]);
}

#[tokio::test]
async fn no_sites_means_no_latest_section() {
    let (feed, _) = feed(full_catalog(), vec![]);
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    assert!(!ids(&outcome).contains(&HomeSectionId::Latest));
}

#[tokio::test]
async fn weekly_sections_with_titles_sit_between_popular_and_latest() {
    let catalog = full_catalog()
        .with_list(
            MediaKind::Anime,
            MediaListKind::TopRated,
            vec![anime(5, "Epsilon", &[])],
        )
        .with_list(
            MediaKind::Anime,
            MediaListKind::Returning,
            vec![anime(6, "Zeta", &[])],
        );
    let (feed, _) = feed(
        catalog,
        vec![source("a").with_latest(vec![item("1/alpha", "Alpha")])],
    );
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    assert_eq!(
        ids(&outcome),
        vec![
            HomeSectionId::Trending,
            HomeSectionId::Seasonal,
            HomeSectionId::Popular,
            HomeSectionId::TopRated,
            HomeSectionId::Returning,
            HomeSectionId::Latest,
        ]
    );
}

#[tokio::test]
async fn weekly_sections_nobody_filled_are_left_out() {
    let (feed, _) = feed(full_catalog(), vec![]);
    let outcome = feed.execute(MediaKind::Anime).await.unwrap();
    assert!(ids(&outcome).iter().all(|id| !id.is_weekly()));
}

#[tokio::test]
async fn comics_get_weekly_sections_too_but_never_a_comeback() {
    let catalog = FakeCatalog::new()
        .with_list(
            MediaKind::Manga,
            MediaListKind::NewThisWeek,
            vec![anime(7, "Eta", &[])],
        )
        .with_list(
            MediaKind::Manga,
            MediaListKind::Returning,
            vec![anime(8, "Theta", &[])],
        );
    let (feed, _) = feed(catalog, vec![]);
    let outcome = feed.execute(MediaKind::Manga).await.unwrap();
    assert_eq!(
        ids(&outcome),
        vec![
            HomeSectionId::Trending,
            HomeSectionId::Popular,
            HomeSectionId::NewThisWeek,
        ]
    );
}

#[test]
fn only_the_four_weekly_ids_are_weekly() {
    assert!(HomeSectionId::TopRated.is_weekly());
    assert!(HomeSectionId::NewThisWeek.is_weekly());
    assert!(HomeSectionId::FinishedThisWeek.is_weekly());
    assert!(HomeSectionId::Returning.is_weekly());
    assert!(!HomeSectionId::Trending.is_weekly());
    assert!(!HomeSectionId::Latest.is_weekly());
}
