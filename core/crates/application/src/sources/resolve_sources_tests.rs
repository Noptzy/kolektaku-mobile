use domain::error::SourceError;
use domain::matching::Confidence;
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore};

use super::resolve_support::{DAY, empty_site, media, order, reference, rig, site_with};

#[tokio::test]
async fn a_title_only_on_the_second_site_is_played_from_it_without_asking_the_person() {
    let rig = rig(vec![
        empty_site("a", 1),
        site_with("b", 5, "b-spy", 2022, 12),
    ]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["b"]);
    assert_eq!(resolved.best().unwrap().item.as_str(), "b-spy");
    assert!(resolved.best().unwrap().confidence.is_automatic());
}

#[tokio::test]
async fn a_title_on_both_sites_keeps_every_link_the_better_ranked_first() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        site_with("b", 5, "b-spy", 2022, 12),
    ]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["a", "b"]);
    assert_eq!(order(&rig.store.snapshot(&reference())).len(), 2);
}

#[tokio::test]
async fn the_site_with_more_episodes_ranks_first() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        site_with("b", 5, "b-spy", 2022, 25),
    ]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["b", "a"]);
}

#[tokio::test]
async fn a_site_that_fails_in_the_middle_does_not_stop_the_other() {
    let broken =
        site_with("a", 1, "a-spy", 2022, 12).failing_with(SourceError::Unavailable("down".into()));
    let rig = rig(vec![broken, site_with("b", 5, "b-spy", 2022, 12)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["b"]);
    assert_eq!(rig.health.recent_failures(&SourceId::new("a")), 1);
}

#[tokio::test]
async fn when_every_site_fails_the_error_is_reported() {
    let rig = rig(vec![
        empty_site("a", 1).failing_with(SourceError::Network("offline".into())),
    ]);
    let error = rig.use_case.execute(&media()).await.unwrap_err();
    assert_eq!(error, SourceError::Network("offline".into()));
}

#[tokio::test]
async fn looking_everywhere_and_finding_nothing_is_not_an_error() {
    let rig = rig(vec![empty_site("a", 1), empty_site("b", 5)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert!(resolved.links.is_empty() && resolved.best().is_none());
    assert!(rig.store.snapshot(&reference()).is_empty());
}

#[tokio::test]
async fn fresh_links_are_used_without_searching_again() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    rig.use_case.execute(&media()).await.unwrap();
    let searches = rig.sources[0].calls().len();
    rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(rig.sources[0].calls().len(), searches);
}

#[tokio::test]
async fn links_older_than_two_weeks_are_searched_again() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    rig.use_case.execute(&media()).await.unwrap();
    let searches = rig.sources[0].calls().len();
    rig.clock.advance(15 * DAY);
    rig.use_case.execute(&media()).await.unwrap();
    assert!(rig.sources[0].calls().len() > searches);
}

#[tokio::test]
async fn a_stale_link_beats_failing_when_the_sites_are_unreachable() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    rig.use_case.execute(&media()).await.unwrap();
    rig.clock.advance(15 * DAY);
    rig.sources[0].set_failure(Some(SourceError::Network("offline".into())));
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["a"]);
}

#[tokio::test]
async fn a_stale_link_beats_nothing_when_the_site_now_finds_nothing() {
    let rig = rig(vec![empty_site("a", 1)]);
    let old = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("a-spy"),
        Confidence::new(0.95),
        1,
    );
    rig.store.save_all(&reference(), vec![old]).await.unwrap();
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["a"]);
    assert_eq!(resolved.best().unwrap().item.as_str(), "a-spy");
}

#[tokio::test]
async fn three_failures_in_a_row_make_the_site_skipped_for_ten_minutes() {
    let rig = rig(vec![
        empty_site("a", 1).failing_with(SourceError::Unavailable("down".into())),
    ]);
    for _ in 0..3 {
        let _ = rig.use_case.execute(&media()).await;
    }
    let before = rig.sources[0].calls().len();
    let _ = rig.use_case.execute(&media()).await;
    assert_eq!(rig.sources[0].calls().len(), before);
    rig.clock.advance(601);
    let _ = rig.use_case.execute(&media()).await;
    assert!(rig.sources[0].calls().len() > before);
}

#[tokio::test]
async fn a_doubtful_match_is_flagged_so_the_person_can_correct_it() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2010, 12)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    let link = resolved.best().unwrap();
    assert!(!link.confidence.is_automatic());
    assert!(resolved.needs_hint(&SourceId::new("a")));
}

#[tokio::test]
async fn a_title_a_site_only_knows_by_a_synonym_is_still_found() {
    use domain::media::MediaKind;
    use domain::source::{ItemId, SourceItem};

    use super::resolve_support::{TITLE, detail};
    use crate::testing::FakeSource;

    let alias = "Spy Family Alias";
    let site = FakeSource::new("a", MediaKind::Anime)
        .with_priority(1)
        .with_search(alias, vec![SourceItem::new(ItemId::new("a-alias"), TITLE)])
        .with_detail(detail("a-alias", TITLE, 2022, 12));
    let rig = rig(vec![site]);
    let mut media = media();
    media.synonyms = vec!["日本語のタイトル".into(), alias.into()];
    let resolved = rig.use_case.execute(&media).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["a"]);
    assert_eq!(resolved.best().unwrap().item.as_str(), "a-alias");
}
