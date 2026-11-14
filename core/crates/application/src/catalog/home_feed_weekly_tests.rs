use domain::media::{MediaKind, MediaListKind};

use super::HomeSectionId;
use super::home_feed_support::{feed, full_catalog, ids};
use super::search_test_support::{anime, item, source};
use crate::testing::FakeCatalog;

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
