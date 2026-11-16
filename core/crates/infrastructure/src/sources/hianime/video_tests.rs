use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;
use domain::stream::StreamPlan;
use domain::stream::ServerVariant;
use serde_json::json;

use super::source_tests::source_over;
use crate::fixtures;
use crate::http::{FakeHttp, HttpResponse};

const EPISODE: &str = "steel-ball-run-jojos-bizarre-adventure-2nd-stage-episode-4-ep-4-i47qir-2bhx1";

fn serving_fixture() -> Arc<FakeHttp> {
    Arc::new(FakeHttp::always(HttpResponse::new(
        200,
        fixtures::hianime("episode.json"),
    )))
}

fn episode_with(sub: &[&str], dub: &[&str]) -> String {
    json!({ "episode": { "slug": "e", "episodeNumber": 1, "link": { "sub": sub, "dub": dub } } })
        .to_string()
}

#[tokio::test]
async fn an_episode_offers_a_sub_and_a_dub_server() {
    let source = source_over(serving_fixture());
    let servers = source.video().unwrap().servers(EPISODE.into()).await.unwrap();
    let described: Vec<(&str, &str)> = servers
        .iter()
        .map(|server| (server.id.as_str(), server.label.as_str()))
        .collect();
    assert_eq!(
        described,
        [("sub-1", "Server 1 · Sub"), ("dub-1", "Server 1 · Dub")]
    );
    let variants: Vec<_> = servers.iter().map(|server| server.variant).collect();
    assert_eq!(
        variants,
        [Some(ServerVariant::Sub), Some(ServerVariant::Dub)]
    );
}

#[tokio::test]
async fn the_plan_opens_the_chosen_embed_in_a_web_view_pinned_to_its_host() {
    let source = source_over(serving_fixture());
    let plan = source
        .video()
        .unwrap()
        .stream_plan(EPISODE.into(), "dub-1".into())
        .await
        .unwrap();
    let StreamPlan::NeedsWebView {
        url,
        script,
        allowed_host,
        ..
    } = plan
    else {
        panic!("expected a web view plan");
    };
    assert!(url.starts_with("https://zokoanime.video/stream/mal/63825/4/dub"));
    assert_eq!(allowed_host, "zokoanime.video");
    assert!(script.contains("jwplayer"));
}

#[tokio::test]
async fn the_server_list_and_the_plan_share_one_request() {
    let http = serving_fixture();
    let source = source_over(http.clone());
    let video = source.video().unwrap();
    video.servers(EPISODE.into()).await.unwrap();
    video
        .stream_plan(EPISODE.into(), "sub-1".into())
        .await
        .unwrap();
    assert_eq!(http.requests().len(), 1);
}

#[tokio::test]
async fn an_unknown_server_or_a_bad_episode_is_not_found() {
    let http = serving_fixture();
    let source = source_over(http.clone());
    let video = source.video().unwrap();
    assert!(matches!(
        video.stream_plan(EPISODE.into(), "sub-9".into()).await,
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        video.stream_plan(EPISODE.into(), "x\";alert(1)".into()).await,
        Err(SourceError::NotFound(_))
    ));
    let before = http.requests().len();
    assert!(matches!(
        video.servers("../admin".into()).await,
        Err(SourceError::NotFound(_))
    ));
    assert_eq!(http.requests().len(), before);
}

#[tokio::test]
async fn an_episode_with_only_unknown_players_is_unavailable() {
    let body = episode_with(&["https://evil.test/embed"], &[]);
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, body)));
    let result = source_over(http).video().unwrap().servers("e".into()).await;
    assert!(matches!(result, Err(SourceError::Unavailable(_))));
}

#[tokio::test]
async fn an_episode_without_links_is_a_markup_change() {
    let body = json!({ "episode": { "slug": "e" } }).to_string();
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, body)));
    let result = source_over(http).video().unwrap().servers("e".into()).await;
    assert!(matches!(result, Err(SourceError::MarkupChanged(_))));
}

#[tokio::test]
async fn a_second_player_is_offered_as_server_two() {
    let body = episode_with(
        &[
            "https://zokoanime.video/stream/mal/1/1/sub",
            "https://megaplay.buzz/stream/s-2/9/sub",
        ],
        &[],
    );
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, body)));
    let source = source_over(http);
    let video = source.video().unwrap();
    let servers = video.servers("e".into()).await.unwrap();
    assert_eq!(servers[1].label, "Server 2 · Sub");
    let plan = video.stream_plan("e".into(), "sub-2".into()).await.unwrap();
    let StreamPlan::NeedsWebView { allowed_host, .. } = plan else {
        panic!("expected a web view plan");
    };
    assert_eq!(allowed_host, "megaplay.buzz");
}

#[test]
fn the_page_payload_is_parsed_through_the_video_source() {
    let source = source_over(serving_fixture());
    let set = source
        .video()
        .unwrap()
        .parse_stream_payload(&fixtures::hianime("payload.json"))
        .unwrap();
    assert_eq!(set.skips.len(), 2);
    assert_eq!(set.subtitles.len(), 4);
    assert!(
        source
            .video()
            .unwrap()
            .parse_stream_payload("nope")
            .is_err()
    );
}
