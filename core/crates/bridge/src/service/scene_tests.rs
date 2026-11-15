use std::sync::Arc;

use application::ports::SourceProvider;
use infrastructure::http::HttpResponse;

use super::scene::{find_scene, open_scene, scene_quota};
use super::service_support::{Folder, ScriptedHttp, offline, state, state_with};
use crate::dto::scene::{DetailReasonDto, SceneMatchDto, SceneOutcomeKind, SceneTargetKind};
use crate::error::BridgeErrorKind;

fn reply(similarity: f64) -> HttpResponse {
    HttpResponse::new(
        200,
        format!(
            r#"{{"error":"","quota":100,"quotaUsed":10,"result":[{{"anilist":{{"id":140960,"isAdult":false,"title":{{"romaji":"Spy x Family"}}}},"episode":1,"from":98,"at":100,"to":102,"similarity":{similarity},"duration":1420}}]}}"#
        ),
    )
}

fn scene(media_id: u64, episode: Option<f64>) -> SceneMatchDto {
    SceneMatchDto {
        media_id,
        episode,
        from_secs: 98.0,
        at_secs: 100.0,
        to_secs: 102.0,
        similarity: 0.97,
        preview_image_url: None,
        title: None,
        duration_secs: Some(1420.0),
    }
}

#[tokio::test]
async fn a_close_match_comes_back_as_a_direct_hit_with_the_quota() {
    let folder = Folder::new();
    let state = state_with(&folder, Vec::new(), ScriptedHttp(Ok(reply(0.97)))).await;
    let finding = find_scene(&state, vec![1, 2, 3]).await.unwrap();
    assert_eq!(finding.kind, SceneOutcomeKind::Direct);
    let best = finding.best.unwrap();
    assert_eq!(best.media_id, 140960);
    assert_eq!(best.episode, Some(1.0));
    assert_eq!(best.title.as_deref(), Some("Spy x Family"));
    assert_eq!(finding.quota_left, Some(90));
}

#[tokio::test]
async fn a_middling_match_comes_back_as_candidates() {
    let folder = Folder::new();
    let state = state_with(&folder, Vec::new(), ScriptedHttp(Ok(reply(0.85)))).await;
    let finding = find_scene(&state, vec![1]).await.unwrap();
    assert_eq!(finding.kind, SceneOutcomeKind::Candidates);
    assert!(finding.best.is_none());
    assert_eq!(finding.candidates.len(), 1);
}

#[tokio::test]
async fn a_weak_match_is_not_found() {
    let folder = Folder::new();
    let state = state_with(&folder, Vec::new(), ScriptedHttp(Ok(reply(0.5)))).await;
    let finding = find_scene(&state, vec![1]).await.unwrap();
    assert_eq!(finding.kind, SceneOutcomeKind::NotFound);
    assert!(finding.candidates.is_empty());
}

#[tokio::test]
async fn the_daily_limit_is_a_quota_error() {
    let folder = Folder::new();
    let http = ScriptedHttp(Ok(HttpResponse::new(402, "{}")));
    let state = state_with(&folder, Vec::new(), http).await;
    let error = find_scene(&state, vec![1]).await.unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::QuotaExceeded);
}

#[tokio::test]
async fn no_connection_is_a_network_error() {
    let folder = Folder::new();
    let state = state_with(&folder, Vec::new(), offline()).await;
    let error = find_scene(&state, vec![1]).await.unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::Network);
}

#[tokio::test]
async fn an_empty_image_is_unsupported() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let error = find_scene(&state, Vec::new()).await.unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::Unsupported);
}

#[tokio::test]
async fn a_scene_of_an_episode_opens_the_player_early() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let target = open_scene(&state, &scene(140960, Some(1.0))).await.unwrap();
    assert_eq!(target.kind, SceneTargetKind::Watch);
    assert_eq!(target.episode, Some(1.0));
    assert_eq!(target.start_secs, Some(97.0));
    assert_eq!(target.duration_secs, Some(1420.0));
    assert_eq!(target.reason, None);
}

#[tokio::test]
async fn a_series_scene_without_an_episode_opens_the_detail_page() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let target = open_scene(&state, &scene(140960, None)).await.unwrap();
    assert_eq!(target.kind, SceneTargetKind::Detail);
    assert_eq!(target.reason, Some(DetailReasonDto::NoEpisode));
}

#[tokio::test]
async fn a_title_nobody_has_opens_the_detail_page_with_a_note() {
    let folder = Folder::new();
    let no_sources: Vec<Arc<dyn SourceProvider>> = Vec::new();
    let state = state_with(&folder, no_sources, offline()).await;
    let target = open_scene(&state, &scene(140960, Some(1.0))).await.unwrap();
    assert_eq!(target.kind, SceneTargetKind::Detail);
    assert_eq!(target.reason, Some(DetailReasonDto::NotAvailable));
}

#[tokio::test]
async fn a_scene_without_a_valid_title_is_refused() {
    let folder = Folder::new();
    let state = state(&folder).await;
    let error = open_scene(&state, &scene(0, Some(1.0))).await.unwrap_err();
    assert_eq!(error.kind, BridgeErrorKind::NotFound);
}

#[tokio::test]
async fn the_quota_can_be_read_before_any_search() {
    let folder = Folder::new();
    let body = r#"{"id":"x","priority":0,"concurrency":1,"quota":100,"quotaUsed":12}"#;
    let state = state_with(
        &folder,
        Vec::new(),
        ScriptedHttp(Ok(HttpResponse::new(200, body))),
    )
    .await;
    assert_eq!(scene_quota(&state).await, Some(88));
}

#[tokio::test]
async fn an_unreachable_service_leaves_the_quota_unknown() {
    let folder = Folder::new();
    let state = state_with(&folder, Vec::new(), offline()).await;
    assert_eq!(scene_quota(&state).await, None);
}
