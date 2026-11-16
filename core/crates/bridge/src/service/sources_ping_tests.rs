use application::testing::FakeSource;
use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceItem};
use std::sync::Arc;

use super::service_support::{Folder, offline, state_with};
use super::sources::ping;
use crate::dto::sources::PingVerdictDto;

fn working() -> FakeSource {
    FakeSource::new("up", MediaKind::Anime)
        .with_latest(vec![SourceItem::new(ItemId::new("a"), "A")])
}

#[tokio::test]
async fn a_source_that_answers_is_online() {
    let folder = Folder::new();
    let state = state_with(&folder, vec![Arc::new(working())], offline()).await;
    let result = ping(&state, "up").await.unwrap();
    assert_eq!(result.id, "up");
    assert_eq!(result.verdict, PingVerdictDto::Online);
}

#[tokio::test]
async fn a_source_that_fails_is_offline() {
    let folder = Folder::new();
    let down = working().failing_with(SourceError::Unavailable("HTTP 522".into()));
    let state = state_with(&folder, vec![Arc::new(down)], offline()).await;
    assert_eq!(
        ping(&state, "up").await.unwrap().verdict,
        PingVerdictDto::Offline
    );
}

#[tokio::test]
async fn a_source_that_answers_but_changed_or_asks_a_challenge_is_changed() {
    for error in [
        SourceError::MarkupChanged("x".into()),
        SourceError::ChallengeRequired("x".into()),
    ] {
        let folder = Folder::new();
        let odd = working().failing_with(error);
        let state = state_with(&folder, vec![Arc::new(odd)], offline()).await;
        assert_eq!(
            ping(&state, "up").await.unwrap().verdict,
            PingVerdictDto::Changed
        );
    }
}

#[tokio::test]
async fn an_unknown_source_is_not_found() {
    let folder = Folder::new();
    let state = state_with(&folder, vec![Arc::new(working())], offline()).await;
    assert!(ping(&state, "ghost").await.is_err());
}
