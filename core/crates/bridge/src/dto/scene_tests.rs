use application::scene::{DetailReason, SceneFinding, SceneOutcome, SceneTarget};
use domain::media::MediaId;
use domain::scene::SceneMatch;

use super::scene::{
    DetailReasonDto, SceneFindingDto, SceneMatchDto, SceneOutcomeKind, SceneTargetDto,
    SceneTargetKind,
};

fn found(id: u64) -> SceneMatch {
    SceneMatch {
        media_id: MediaId::new(id).unwrap(),
        episode: Some(4.0),
        from_secs: 1.0,
        at_secs: 2.0,
        to_secs: 3.0,
        similarity: 0.93,
        preview_image_url: Some("https://x.test/p.jpg".into()),
        title: Some("Judul".into()),
        is_adult: false,
        duration_secs: Some(1400.0),
    }
}

#[test]
fn a_match_survives_the_round_trip_to_the_bridge_and_back() {
    let dto = SceneMatchDto::from(&found(7));
    assert_eq!(dto.media_id, 7);
    assert_eq!(dto.episode, Some(4.0));
    assert_eq!(dto.title.as_deref(), Some("Judul"));
    assert_eq!(dto.into_domain().unwrap(), found(7));
}

#[test]
fn a_match_without_a_valid_title_id_cannot_come_back() {
    let mut dto = SceneMatchDto::from(&found(7));
    dto.media_id = 0;
    assert!(dto.into_domain().is_err());
}

#[test]
fn a_direct_finding_has_a_best_match_and_the_others() {
    let finding = SceneFinding {
        outcome: SceneOutcome::Direct {
            best: found(1),
            others: vec![found(2)],
        },
        quota_left: Some(80),
    };
    let dto = SceneFindingDto::from(&finding);
    assert_eq!(dto.kind, SceneOutcomeKind::Direct);
    assert_eq!(dto.best.unwrap().media_id, 1);
    assert_eq!(dto.candidates.len(), 1);
    assert_eq!(dto.quota_left, Some(80));
}

#[test]
fn candidates_have_no_best_match() {
    let finding = SceneFinding {
        outcome: SceneOutcome::Candidates(vec![found(1), found(2)]),
        quota_left: None,
    };
    let dto = SceneFindingDto::from(&finding);
    assert_eq!(dto.kind, SceneOutcomeKind::Candidates);
    assert!(dto.best.is_none());
    assert_eq!(dto.candidates.len(), 2);
}

#[test]
fn nothing_found_is_empty() {
    let finding = SceneFinding {
        outcome: SceneOutcome::NotFound,
        quota_left: Some(1),
    };
    let dto = SceneFindingDto::from(&finding);
    assert_eq!(dto.kind, SceneOutcomeKind::NotFound);
    assert!(dto.best.is_none() && dto.candidates.is_empty());
}

#[test]
fn a_watch_target_carries_episode_and_moment() {
    let dto = SceneTargetDto::from(&SceneTarget::Watch {
        media: MediaId::new(9).unwrap(),
        episode: 2.0,
        start_secs: 97.0,
        duration_secs: Some(1420.0),
    });
    assert_eq!(dto.kind, SceneTargetKind::Watch);
    assert_eq!(dto.episode, Some(2.0));
    assert_eq!(dto.start_secs, Some(97.0));
    assert_eq!(dto.reason, None);
}

#[test]
fn a_detail_target_carries_only_the_reason() {
    for (reason, expected) in [
        (DetailReason::NotAvailable, DetailReasonDto::NotAvailable),
        (DetailReason::NoEpisode, DetailReasonDto::NoEpisode),
    ] {
        let dto = SceneTargetDto::from(&SceneTarget::Detail {
            media: MediaId::new(9).unwrap(),
            reason,
        });
        assert_eq!(dto.kind, SceneTargetKind::Detail);
        assert_eq!(dto.reason, Some(expected));
        assert_eq!((dto.episode, dto.start_secs), (None, None));
    }
}
