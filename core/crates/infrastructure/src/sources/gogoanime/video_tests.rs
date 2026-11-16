use std::sync::Arc;

use application::ports::SourceProvider;
use domain::error::SourceError;
use domain::stream::{ServerVariant, StreamPlan};

use super::source_tests::source_over;
use crate::fixtures;
use crate::http::{FakeHttp, HttpRequest, HttpResponse};

const EPISODE: &str = "oshi-no-ko-season-2-episode-13";

fn serving(episode: &'static str, wrapper: &'static str) -> Arc<FakeHttp> {
    Arc::new(FakeHttp::replying(move |request: &HttpRequest| {
        Ok(if request.url.contains("/newplayer.php") {
            HttpResponse::new(200, fixtures::gogoanime(wrapper))
        } else if request.url.contains(EPISODE) {
            HttpResponse::new(200, fixtures::gogoanime(episode))
        } else {
            HttpResponse::new(404, "")
        })
    }))
}

#[tokio::test]
async fn an_episode_offers_its_servers_with_their_audio() {
    let source = source_over(serving("episode.html", "player.html"));
    let servers = source.video().unwrap().servers(EPISODE.into()).await.unwrap();
    let ids: Vec<&str> = servers.iter().map(|server| server.id.as_str()).collect();
    assert_eq!(ids, ["hd-1", "hd-2"]);
    assert_eq!(servers[0].label, "Server 1 · Sub");
    assert_eq!(servers[0].variant, Some(ServerVariant::Sub));
    assert_eq!(servers[0].audio.as_deref(), Some("ja"));
}

#[tokio::test]
async fn a_dub_episode_offers_dub_servers() {
    let source = source_over(serving("episode-dub.html", "player.html"));
    let servers = source.video().unwrap().servers(EPISODE.into()).await.unwrap();
    assert_eq!(servers[0].variant, Some(ServerVariant::Dub));
    assert_eq!(servers[0].audio.as_deref(), Some("en"));
}

#[tokio::test]
async fn the_plan_loads_the_embedded_player_with_the_wrapper_as_referer() {
    let source = source_over(serving("episode.html", "player.html"));
    let plan = source
        .video()
        .unwrap()
        .stream_plan(EPISODE.into(), "hd-1".into())
        .await
        .unwrap();
    let StreamPlan::NeedsWebView {
        url,
        script,
        allowed_host,
        referer,
    } = plan
    else {
        panic!("expected a web view plan");
    };
    assert!(url.starts_with("https://megaplay.buzz/stream/s-2/128473/sub"));
    assert_eq!(allowed_host, "megaplay.buzz");
    assert_eq!(referer.as_deref(), Some("https://gogoanime.me.uk/"));
    assert!(script.contains("jwplayer"));
}

#[tokio::test]
async fn an_unknown_server_is_not_found() {
    let source = source_over(serving("episode.html", "player.html"));
    let error = source
        .video()
        .unwrap()
        .stream_plan(EPISODE.into(), "hd-9".into())
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::NotFound(_)));
}

#[tokio::test]
async fn a_wrapper_without_a_known_player_is_a_markup_change() {
    let http = Arc::new(FakeHttp::replying(|request: &HttpRequest| {
        Ok(if request.url.contains("/newplayer.php") {
            HttpResponse::new(200, "<p>nothing</p>")
        } else {
            HttpResponse::new(200, fixtures::gogoanime("episode.html"))
        })
    }));
    let error = source_over(http)
        .video()
        .unwrap()
        .stream_plan(EPISODE.into(), "hd-1".into())
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::MarkupChanged(_)));
}

#[tokio::test]
async fn an_episode_without_any_player_is_unavailable() {
    let http = Arc::new(FakeHttp::always(HttpResponse::new(200, "<html></html>")));
    let error = source_over(http)
        .video()
        .unwrap()
        .servers(EPISODE.into())
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::Unavailable(_)));
}

#[tokio::test]
async fn an_unsafe_episode_is_refused_without_a_request() {
    let http = serving("episode.html", "player.html");
    let source = source_over(http.clone());
    let error = source
        .video()
        .unwrap()
        .servers("../x".into())
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::NotFound(_)));
    assert!(http.requests().is_empty());
}

#[test]
fn the_stream_payload_is_parsed_like_any_other_player_payload() {
    let source = source_over(Arc::new(FakeHttp::always(HttpResponse::new(200, ""))));
    let set = source
        .video()
        .unwrap()
        .parse_stream_payload(&fixtures::gogoanime("payload.json"))
        .unwrap();
    assert!(!set.sources.is_empty());
}
