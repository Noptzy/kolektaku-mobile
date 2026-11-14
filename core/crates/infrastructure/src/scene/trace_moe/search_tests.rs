use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Duration;

use application::ports::{BoxFuture, SceneSearch};
use domain::error::SourceError;

use super::TraceMoeSceneSearch;
use crate::fixtures;
use crate::http::{FakeHttp, FakePause, HttpClient, HttpMethod, HttpRequest, HttpResponse};

fn search_with(http: Arc<FakeHttp>) -> TraceMoeSceneSearch {
    TraceMoeSceneSearch::new(http, Arc::new(FakePause::at(0)))
}

fn sample_reply() -> HttpResponse {
    HttpResponse::new(200, fixtures::trace_moe("search_sample.json"))
}

fn reply_with(result: &str) -> HttpResponse {
    HttpResponse::new(
        200,
        format!(r#"{{"error":"","quota":100,"quotaUsed":4,"result":[{result}]}}"#),
    )
}

#[tokio::test]
async fn the_official_sample_finds_gochuumon_episode_one() {
    let http = Arc::new(FakeHttp::always(sample_reply()));
    let reply = search_with(http).find(vec![1, 2, 3]).await.unwrap();
    let best = &reply.matches[0];
    assert_eq!(best.media_id.get(), 21034);
    assert_eq!(best.episode, Some(1.0));
    assert!((best.at_secs - 279.7795).abs() < 0.001);
    assert!((best.from_secs - 272.1886).abs() < 0.001);
    assert!((best.to_secs - 282.6574).abs() < 0.001);
    assert!(best.similarity > 0.99);
    assert!(!best.is_adult);
    assert_eq!(
        best.title.as_deref(),
        Some("Is the Order a Rabbit?? Season 2")
    );
    assert!(best.preview_image_url.is_some());
    assert!(best.duration_secs.unwrap() > 1000.0);
    assert_eq!(reply.matches.len(), 4);
}

#[tokio::test]
async fn the_quota_left_comes_from_the_reply() {
    let http = Arc::new(FakeHttp::always(reply_with("")));
    let reply = search_with(http).find(vec![1]).await.unwrap();
    assert_eq!(reply.quota_left, Some(96));
    assert!(reply.matches.is_empty());
}

#[tokio::test]
async fn the_image_is_posted_as_raw_bytes_to_the_search_endpoint() {
    let http = Arc::new(FakeHttp::always(sample_reply()));
    search_with(http.clone()).find(vec![9, 8, 7]).await.unwrap();
    let request = &http.requests()[0];
    assert_eq!(request.method, HttpMethod::Post);
    assert!(request.url.starts_with("https://api.trace.moe/search?"));
    assert!(request.url.contains("cutBorders"));
    assert!(request.url.contains("anilistInfo"));
    assert_eq!(request.bytes.as_deref(), Some(&[9u8, 8, 7][..]));
    assert_eq!(request.body, None);
    assert_eq!(request.header("content-type"), Some("image/jpeg"));
}

#[tokio::test]
async fn an_empty_image_is_refused_without_a_request() {
    let http = Arc::new(FakeHttp::always(sample_reply()));
    let result = search_with(http.clone()).find(Vec::new()).await;
    assert_eq!(result, Err(SourceError::Unsupported("empty image".into())));
    assert!(http.requests().is_empty());
}

#[tokio::test]
async fn adult_results_are_flagged_for_the_caller_to_drop() {
    let http = Arc::new(FakeHttp::always(reply_with(
        r#"{"anilist":{"id":5,"isAdult":true,"title":{"romaji":"X"}},"episode":2,"from":1,"at":2,"to":3,"similarity":0.95}"#,
    )));
    let reply = search_with(http).find(vec![1]).await.unwrap();
    assert!(reply.matches[0].is_adult);
}

#[tokio::test]
async fn episodes_come_as_numbers_text_the_first_of_a_list_or_nothing() {
    let results = [
        r#"{"anilist":{"id":1},"episode":3,"from":0,"at":1,"to":2,"similarity":0.9}"#,
        r#"{"anilist":{"id":2},"episode":"4","from":0,"at":1,"to":2,"similarity":0.9}"#,
        r#"{"anilist":{"id":3},"episode":"OVA","from":0,"at":1,"to":2,"similarity":0.9}"#,
        r#"{"anilist":{"id":4},"episode":[1,2],"from":0,"at":1,"to":2,"similarity":0.9}"#,
        r#"{"anilist":{"id":5},"episode":null,"from":0,"at":1,"to":2,"similarity":0.9}"#,
        r#"{"anilist":{"id":6},"from":0,"at":1,"to":2,"similarity":0.9}"#,
    ];
    let http = Arc::new(FakeHttp::always(reply_with(&results.join(","))));
    let reply = search_with(http).find(vec![1]).await.unwrap();
    let episodes: Vec<_> = reply.matches.iter().map(|found| found.episode).collect();
    assert_eq!(
        episodes,
        vec![Some(3.0), Some(4.0), None, Some(1.0), None, None]
    );
}

#[tokio::test]
async fn a_bare_numeric_id_and_a_missing_moment_still_map() {
    let http = Arc::new(FakeHttp::always(reply_with(
        r#"{"anilist":21034,"episode":1,"from":10,"to":20,"similarity":0.9}"#,
    )));
    let reply = search_with(http).find(vec![1]).await.unwrap();
    assert_eq!(reply.matches[0].media_id.get(), 21034);
    assert_eq!(reply.matches[0].at_secs, 15.0);
    assert_eq!(reply.matches[0].title, None);
}

#[tokio::test]
async fn an_invalid_media_id_is_skipped() {
    let http = Arc::new(FakeHttp::always(reply_with(
        r#"{"anilist":{"id":0},"episode":1,"from":0,"at":1,"to":2,"similarity":0.9}"#,
    )));
    let reply = search_with(http).find(vec![1]).await.unwrap();
    assert!(reply.matches.is_empty());
}

struct SlowHttp {
    active: AtomicUsize,
    busiest: AtomicUsize,
}

impl HttpClient for SlowHttp {
    fn send(&self, _request: HttpRequest) -> BoxFuture<'_, Result<HttpResponse, SourceError>> {
        Box::pin(async move {
            let now = self.active.fetch_add(1, Ordering::SeqCst) + 1;
            self.busiest.fetch_max(now, Ordering::SeqCst);
            tokio::time::sleep(Duration::from_millis(20)).await;
            self.active.fetch_sub(1, Ordering::SeqCst);
            Ok(reply_with(""))
        })
    }
}

#[tokio::test]
async fn searches_wait_for_their_turn_one_at_a_time() {
    let http = Arc::new(SlowHttp {
        active: AtomicUsize::new(0),
        busiest: AtomicUsize::new(0),
    });
    let search = Arc::new(TraceMoeSceneSearch::new(
        http.clone(),
        Arc::new(FakePause::at(0)),
    ));
    let tasks: Vec<_> = (0..4)
        .map(|_| {
            let search = search.clone();
            tokio::spawn(async move { search.find(vec![1]).await })
        })
        .collect();
    for task in tasks {
        task.await.unwrap().unwrap();
    }
    assert_eq!(http.busiest.load(Ordering::SeqCst), 1);
}
