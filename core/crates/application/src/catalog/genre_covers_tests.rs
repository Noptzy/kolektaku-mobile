use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaKind;

use super::genre_covers::{GenreCovers, assign_covers};
use crate::testing::FakeCatalog;

fn names(list: &[&str]) -> Vec<String> {
    list.iter().map(ToString::to_string).collect()
}

fn lists(list: &[&[&str]]) -> Vec<Vec<String>> {
    list.iter().map(|urls| names(urls)).collect()
}

fn urls(covers: &[super::GenreCover]) -> Vec<&str> {
    covers
        .iter()
        .map(|cover| cover.cover_url.as_str())
        .collect()
}

#[test]
fn every_genre_takes_its_first_cover() {
    let covers = assign_covers(&names(&["A", "B"]), &lists(&[&["a1", "a2"], &["b1"]]));
    assert_eq!(urls(&covers), vec!["a1", "b1"]);
}

#[test]
fn a_cover_already_used_is_skipped_for_the_next_candidate() {
    let covers = assign_covers(&names(&["A", "B"]), &lists(&[&["x"], &["x", "y"]]));
    assert_eq!(urls(&covers), vec!["x", "y"]);
}

#[test]
fn a_genre_with_only_used_covers_keeps_its_own_first() {
    let covers = assign_covers(&names(&["A", "B"]), &lists(&[&["x"], &["x"]]));
    assert_eq!(urls(&covers), vec!["x", "x"]);
}

#[test]
fn a_genre_without_covers_gets_none_and_never_borrows_from_another() {
    let genres = names(&["A", "B", "Award Winning"]);
    let covers = assign_covers(&genres, &lists(&[&["a1"], &["b1"], &[]]));
    let named: Vec<&str> = covers.iter().map(|cover| cover.genre.as_str()).collect();
    assert_eq!(named, vec!["A", "B"]);
}

#[test]
fn without_any_cover_nothing_is_invented() {
    assert!(assign_covers(&names(&["A"]), &lists(&[&[]])).is_empty());
    assert!(assign_covers(&names(&["A"]), &[]).is_empty());
}

#[test]
fn covers_keep_the_order_of_the_genres() {
    let covers = assign_covers(&names(&["B", "A"]), &lists(&[&["b1"], &["a1"]]));
    let genres: Vec<&str> = covers.iter().map(|cover| cover.genre.as_str()).collect();
    assert_eq!(genres, vec!["B", "A"]);
}

#[tokio::test]
async fn the_use_case_asks_the_catalog_once_for_all_genres() {
    let catalog = Arc::new(
        FakeCatalog::new()
            .with_covers(MediaKind::Anime, "Action", &["a1"])
            .with_covers(MediaKind::Anime, "Drama", &["d1"]),
    );
    let covers = GenreCovers::new(catalog.clone())
        .execute(MediaKind::Anime, &names(&["Action", "Drama"]))
        .await
        .unwrap();
    assert_eq!(urls(&covers), vec!["a1", "d1"]);
    assert_eq!(catalog.calls(), vec!["genre_covers anime 2".to_string()]);
}

#[tokio::test]
async fn no_genres_means_no_request() {
    let catalog = Arc::new(FakeCatalog::new());
    let covers = GenreCovers::new(catalog.clone())
        .execute(MediaKind::Anime, &[])
        .await
        .unwrap();
    assert!(covers.is_empty());
    assert!(catalog.calls().is_empty());
}

#[tokio::test]
async fn a_catalog_failure_reaches_the_caller() {
    let catalog = Arc::new(FakeCatalog::new().failing_with(SourceError::Network("down".into())));
    let result = GenreCovers::new(catalog)
        .execute(MediaKind::Anime, &names(&["Action"]))
        .await;
    assert!(matches!(result, Err(SourceError::Network(_))));
}
