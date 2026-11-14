use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;
use domain::source::ItemId;
use serde_json::{Value, json};

use super::source_tests::source_over;
use crate::fixtures;
use crate::http::{FakeHttp, HttpResponse};

const SLUG: &str = "steel-ball-run-jojo's-bizarre-adventure-2nd-3rd-stage-13m7yk";
const OBJECT_ID: &str = "6ab63dce32e4b6276712b562";

fn ok(body: impl Into<String>) -> Result<HttpResponse, SourceError> {
    Ok(HttpResponse::new(200, body))
}

fn anime(total: &str) -> String {
    json!({ "anime": { "_id": OBJECT_ID, "title": "Seri", "slug": "seri", "totalEpisodes": total } })
        .to_string()
}

fn window(from: u32, to: u32, total: u32) -> String {
    let episodes: Vec<Value> = (from..=to)
        .map(|number| json!({ "episodeNumber": number, "slug": format!("seri-episode-{number}") }))
        .collect();
    json!({ "total": total, "episodes": episodes }).to_string()
}

#[tokio::test]
async fn the_real_listing_becomes_eight_sorted_units() {
    let http = Arc::new(FakeHttp::scripted(vec![
        ok(fixtures::hianime("anime.json")),
        ok(fixtures::hianime("episodes.json")),
    ]));
    let units = source_over(http.clone())
        .units(ItemId::new(SLUG))
        .await
        .unwrap();
    assert_eq!(units.len(), 8);
    assert_eq!(units[0].number, 1.0);
    assert_eq!(units[7].label, "Episode 8");
    assert!(units.windows(2).all(|pair| pair[0].number < pair[1].number));
    let asked = http.requests();
    assert_eq!(asked.len(), 2);
    assert!(asked[1].url.ends_with(&format!("/api/episodes/{OBJECT_ID}?start=1&end=100")));
}

#[tokio::test]
async fn a_long_series_is_fetched_in_windows_of_one_hundred() {
    let http = Arc::new(FakeHttp::scripted(vec![
        ok(anime("150")),
        ok(window(1, 100, 150)),
        ok(window(101, 150, 150)),
    ]));
    let units = source_over(http.clone()).units(ItemId::new("seri")).await.unwrap();
    assert_eq!(units.len(), 150);
    assert_eq!(units[149].number, 150.0);
    let asked = http.requests();
    assert_eq!(asked.len(), 3);
    assert!(asked[2].url.ends_with("start=101&end=200"));
}

#[tokio::test]
async fn the_walk_stops_at_the_first_empty_window() {
    let http = Arc::new(FakeHttp::scripted(vec![
        ok(anime("500")),
        ok(window(1, 100, 500)),
        ok(json!({ "total": 500, "episodes": [] }).to_string()),
    ]));
    let units = source_over(http.clone()).units(ItemId::new("seri")).await.unwrap();
    assert_eq!(units.len(), 100);
    assert_eq!(http.requests().len(), 3);
}

#[tokio::test]
async fn a_site_that_never_ends_cannot_loop_the_app_forever() {
    let http = Arc::new(FakeHttp::replying(|request| {
        if request.url.contains("/api/episodes/") {
            Ok(HttpResponse::new(
                200,
                json!({ "total": 1_000_000, "episodes": [
                    { "episodeNumber": 1, "slug": "x" }
                ] })
                .to_string(),
            ))
        } else {
            Ok(HttpResponse::new(200, anime("1000000")))
        }
    }));
    let _ = source_over(http.clone()).units(ItemId::new("seri")).await.unwrap();
    assert_eq!(http.requests().len(), 31);
}

#[tokio::test]
async fn a_title_with_no_episodes_yet_has_an_empty_list() {
    let http = Arc::new(FakeHttp::scripted(vec![
        ok(anime("0")),
        ok(json!({ "total": 0, "episodes": [] }).to_string()),
    ]));
    let units = source_over(http).units(ItemId::new("seri")).await.unwrap();
    assert!(units.is_empty());
}

#[tokio::test]
async fn a_missing_title_id_or_episode_list_is_a_markup_change() {
    let no_id = json!({ "anime": { "title": "Seri", "slug": "seri" } }).to_string();
    let http = Arc::new(FakeHttp::scripted(vec![ok(no_id)]));
    assert!(matches!(
        source_over(http).units(ItemId::new("seri")).await,
        Err(SourceError::MarkupChanged(_))
    ));
    let http = Arc::new(FakeHttp::scripted(vec![ok(anime("3")), ok(r#"{"total":3}"#)]));
    assert!(matches!(
        source_over(http).units(ItemId::new("seri")).await,
        Err(SourceError::MarkupChanged(_))
    ));
}

#[tokio::test]
async fn a_failing_window_is_reported() {
    let http = Arc::new(FakeHttp::scripted(vec![
        ok(anime("150")),
        ok(window(1, 100, 150)),
        Ok(HttpResponse::new(502, "")),
    ]));
    assert!(matches!(
        source_over(http).units(ItemId::new("seri")).await,
        Err(SourceError::Unavailable(_))
    ));
}

#[tokio::test]
async fn an_unusable_title_id_is_never_put_into_a_url() {
    let bad = json!({ "anime": { "_id": "../etc", "slug": "seri", "title": "S" } }).to_string();
    let http = Arc::new(FakeHttp::scripted(vec![ok(bad)]));
    assert!(matches!(
        source_over(http.clone()).units(ItemId::new("seri")).await,
        Err(SourceError::NotFound(_))
    ));
    assert_eq!(http.requests().len(), 1);
}
