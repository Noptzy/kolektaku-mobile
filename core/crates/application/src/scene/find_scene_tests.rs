use std::sync::Arc;

use domain::error::SourceError;
use domain::media::MediaId;
use domain::scene::{SceneMatch, SceneReply};

use super::{FindScene, MAX_CANDIDATES, SceneOutcome};
use crate::testing::FakeSceneSearch;

fn scene(id: u64, episode: Option<f64>, similarity: f32) -> SceneMatch {
    SceneMatch {
        media_id: MediaId::new(id).unwrap(),
        episode,
        from_secs: 10.0,
        at_secs: 12.0,
        to_secs: 14.0,
        similarity,
        preview_image_url: None,
        title: Some(format!("title {id}")),
        is_adult: false,
        duration_secs: Some(1400.0),
    }
}

fn adult(mut found: SceneMatch) -> SceneMatch {
    found.is_adult = true;
    found
}

async fn outcome_of(matches: Vec<SceneMatch>) -> SceneOutcome {
    let search = Arc::new(FakeSceneSearch::returning(matches));
    FindScene::new(search)
        .execute(vec![1])
        .await
        .unwrap()
        .outcome
}

#[tokio::test]
async fn a_very_similar_scene_is_opened_straight_away() {
    let outcome = outcome_of(vec![scene(1, Some(5.0), 0.95), scene(2, Some(1.0), 0.84)]).await;
    let SceneOutcome::Direct { best, others } = outcome else {
        panic!("expected a direct hit");
    };
    assert_eq!(best.media_id.get(), 1);
    assert_eq!(others.len(), 1);
    assert_eq!(others[0].media_id.get(), 2);
}

#[tokio::test]
async fn exactly_ninety_percent_is_still_direct() {
    let outcome = outcome_of(vec![scene(1, Some(1.0), 0.90)]).await;
    assert!(matches!(outcome, SceneOutcome::Direct { .. }));
}

#[tokio::test]
async fn a_middling_match_is_offered_as_candidates() {
    let outcome = outcome_of(vec![scene(1, Some(5.0), 0.85), scene(2, Some(2.0), 0.81)]).await;
    let SceneOutcome::Candidates(list) = outcome else {
        panic!("expected candidates");
    };
    assert_eq!(list.len(), 2);
    assert_eq!(list[0].media_id.get(), 1);
}

#[tokio::test]
async fn exactly_eighty_percent_is_a_candidate() {
    let outcome = outcome_of(vec![scene(1, Some(1.0), 0.80)]).await;
    assert!(matches!(outcome, SceneOutcome::Candidates(_)));
}

#[tokio::test]
async fn a_weak_or_empty_answer_is_not_found() {
    assert_eq!(
        outcome_of(vec![scene(1, Some(1.0), 0.79)]).await,
        SceneOutcome::NotFound
    );
    assert_eq!(outcome_of(Vec::new()).await, SceneOutcome::NotFound);
}

#[tokio::test]
async fn adult_results_never_get_through() {
    let only_adult = outcome_of(vec![adult(scene(1, Some(1.0), 0.99))]).await;
    assert_eq!(only_adult, SceneOutcome::NotFound);
    let mixed = outcome_of(vec![
        adult(scene(1, Some(1.0), 0.99)),
        scene(2, Some(3.0), 0.92),
    ])
    .await;
    let SceneOutcome::Direct { best, others } = mixed else {
        panic!("expected the clean result");
    };
    assert_eq!(best.media_id.get(), 2);
    assert!(others.is_empty());
}

#[tokio::test]
async fn results_are_ordered_by_similarity_whatever_the_input_order() {
    let outcome = outcome_of(vec![
        scene(1, Some(1.0), 0.82),
        scene(2, Some(1.0), 0.88),
        scene(3, Some(1.0), 0.85),
    ])
    .await;
    let SceneOutcome::Candidates(list) = outcome else {
        panic!("expected candidates");
    };
    let ids: Vec<u64> = list.iter().map(|found| found.media_id.get()).collect();
    assert_eq!(ids, vec![2, 3, 1]);
}

#[tokio::test]
async fn the_same_episode_found_twice_counts_once() {
    let outcome = outcome_of(vec![
        scene(1, Some(5.0), 0.93),
        scene(1, Some(5.0), 0.91),
        scene(1, Some(6.0), 0.89),
    ])
    .await;
    let SceneOutcome::Direct { best, others } = outcome else {
        panic!("expected a direct hit");
    };
    assert_eq!(best.similarity, 0.93);
    assert_eq!(others.len(), 1);
    assert_eq!(others[0].episode, Some(6.0));
}

#[tokio::test]
async fn at_most_five_candidates_are_returned() {
    let many: Vec<SceneMatch> = (1..=9).map(|id| scene(id, Some(1.0), 0.85)).collect();
    let SceneOutcome::Candidates(list) = outcome_of(many).await else {
        panic!("expected candidates");
    };
    assert_eq!(list.len(), MAX_CANDIDATES);
}

#[tokio::test]
async fn a_direct_hit_keeps_room_for_four_others() {
    let mut many: Vec<SceneMatch> = (2..=9).map(|id| scene(id, Some(1.0), 0.85)).collect();
    many.push(scene(1, Some(1.0), 0.97));
    let SceneOutcome::Direct { others, .. } = outcome_of(many).await else {
        panic!("expected a direct hit");
    };
    assert_eq!(others.len(), MAX_CANDIDATES - 1);
}

#[tokio::test]
async fn the_quota_left_is_passed_along() {
    let search = Arc::new(FakeSceneSearch::replying(SceneReply {
        matches: Vec::new(),
        quota_left: Some(42),
    }));
    let finding = FindScene::new(search).execute(vec![1]).await.unwrap();
    assert_eq!(finding.quota_left, Some(42));
}

#[tokio::test]
async fn the_image_reaches_the_search_untouched() {
    let search = Arc::new(FakeSceneSearch::returning(Vec::new()));
    FindScene::new(search.clone())
        .execute(vec![0; 123])
        .await
        .unwrap();
    assert_eq!(search.image_sizes(), vec![123]);
}

#[tokio::test]
async fn a_failure_of_the_search_is_passed_on() {
    let search = Arc::new(FakeSceneSearch::failing_with(SourceError::QuotaExceeded));
    let result = FindScene::new(search).execute(vec![1]).await;
    assert_eq!(result, Err(SourceError::QuotaExceeded));
}
