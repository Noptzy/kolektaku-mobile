use std::sync::Arc;

use application::ports::SourceProvider;
use application::testing::FakeClock;
use domain::error::SourceError;
use domain::source::ItemId;

use super::source_tests::{popover_page, site};
use super::KuramanimeSource;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};

const BASE: &str = "https://v20.kuramanime.example";

#[tokio::test]
async fn units_of_a_single_page_are_sorted_lowest_first() {
    let (source, _) = site(vec![(
        "/anime/50/one-piece",
        fixtures::kuramanime("detail-small.html"),
    )]);
    let units = source.units(ItemId::new("50/one-piece")).await.unwrap();
    let numbers: Vec<f64> = units.iter().map(|unit| unit.number).collect();
    assert_eq!(numbers, vec![1144.0, 1145.0]);
}

#[tokio::test]
async fn units_follow_the_episode_pages_until_there_is_no_next_one() {
    let (source, http) = site(vec![
        ("/anime/7/long?page=2", popover_page(21..=40, true)),
        ("/anime/7/long?page=3", popover_page(41..=45, false)),
        ("/anime/7/long", popover_page(1..=20, true)),
    ]);
    let units = source.units(ItemId::new("7/long")).await.unwrap();
    assert_eq!(units.len(), 45);
    assert_eq!(units.first().map(|unit| unit.number), Some(1.0));
    assert_eq!(units.last().map(|unit| unit.number), Some(45.0));
    assert_eq!(http.requests().len(), 1 + 6);
}

#[tokio::test]
async fn a_failing_episode_page_fails_the_whole_listing() {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        if request.url.ends_with("/anime/7/long") {
            Ok(HttpResponse::new(200, popover_page(1..=20, true)))
        } else {
            Ok(HttpResponse::new(404, ""))
        }
    }));
    let source = KuramanimeSource::new(http, Arc::new(FakeClock::at(0)), BASE, 1).unwrap();
    let result = source.units(ItemId::new("7/long")).await;
    assert!(matches!(result, Err(SourceError::NotFound(_))));
}

#[tokio::test]
async fn a_title_that_has_not_aired_yet_has_no_units_but_is_not_an_error() {
    let upcoming = r#"<div class="anime__details__title"><h3>Upcoming</h3></div>"#.to_string();
    let (source, _) = site(vec![("/anime/9/upcoming", upcoming)]);
    assert!(source.units(ItemId::new("9/upcoming")).await.unwrap().is_empty());
}

#[tokio::test]
async fn a_page_that_is_not_a_detail_page_is_a_markup_change_for_units() {
    let (source, _) = site(vec![("/anime/9/upcoming", "<main>redesigned</main>".into())]);
    let result = source.units(ItemId::new("9/upcoming")).await;
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}
