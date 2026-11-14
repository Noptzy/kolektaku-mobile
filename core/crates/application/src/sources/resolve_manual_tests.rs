use domain::matching::Confidence;
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore};

use super::resolve_support::{empty_site, media, order, reference, rig, site_with};

#[tokio::test]
async fn a_manual_choice_wins_over_a_better_automatic_match() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        site_with("b", 5, "b-spy", 2022, 12),
    ]);
    rig.use_case.execute(&media()).await.unwrap();
    let resolved = rig
        .use_case
        .choose(&reference(), SourceId::new("b"), ItemId::new("b-other"))
        .await
        .unwrap();
    assert_eq!(order(&resolved.links), vec!["b", "a"]);
    assert!(resolved.links[0].manual);
    assert_eq!(resolved.links[0].item.as_str(), "b-other");
}

#[tokio::test]
async fn a_manual_choice_survives_later_resolving_without_a_new_search() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        site_with("b", 5, "b-spy", 2022, 12),
    ]);
    rig.use_case.execute(&media()).await.unwrap();
    rig.use_case
        .choose(&reference(), SourceId::new("b"), ItemId::new("b-other"))
        .await
        .unwrap();
    let calls = rig.sources[1].calls().len();
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(resolved.best().unwrap().item.as_str(), "b-other");
    assert_eq!(rig.sources[1].calls().len(), calls);
}

#[tokio::test]
async fn choosing_on_a_site_replaces_only_that_sites_link() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        site_with("b", 5, "b-spy", 2022, 12),
    ]);
    rig.use_case.execute(&media()).await.unwrap();
    rig.use_case
        .choose(&reference(), SourceId::new("a"), ItemId::new("a-other"))
        .await
        .unwrap();
    let saved = rig.store.snapshot(&reference());
    assert_eq!(saved.len(), 2);
    assert!(
        saved
            .iter()
            .any(|link| link.source.as_str() == "b" && link.item.as_str() == "b-spy")
    );
}

#[tokio::test]
async fn forgetting_makes_the_next_resolve_search_again() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    rig.use_case.execute(&media()).await.unwrap();
    rig.use_case.forget(&reference()).await.unwrap();
    assert!(rig.store.snapshot(&reference()).is_empty());
    let searches = rig.sources[0].calls().len();
    rig.use_case.execute(&media()).await.unwrap();
    assert!(rig.sources[0].calls().len() > searches);
}

#[tokio::test]
async fn a_link_taken_from_a_list_is_verified_by_the_detail_instead_of_searching() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    let from_list = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("a-spy"),
        Confidence::new(0.84),
        rig.clock_now(),
    );
    rig.store
        .save_all(&reference(), vec![from_list])
        .await
        .unwrap();
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert!(resolved.best().unwrap().confidence.is_automatic());
    assert_eq!(rig.sources[0].calls(), vec!["detail a-spy"]);
}

#[tokio::test]
async fn a_list_link_that_fails_verification_falls_back_to_searching() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    let wrong = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("not-there"),
        Confidence::new(0.84),
        rig.clock_now(),
    );
    rig.store.save_all(&reference(), vec![wrong]).await.unwrap();
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(resolved.best().unwrap().item.as_str(), "a-spy");
}

#[tokio::test]
async fn links_to_sites_that_are_switched_off_are_hidden_but_not_forgotten() {
    let rig = rig(vec![site_with("a", 1, "a-spy", 2022, 12)]);
    let gone = SourceLink::chosen_by_user(SourceId::new("retired"), ItemId::new("old"), 1);
    rig.store.save_all(&reference(), vec![gone]).await.unwrap();
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["a"]);
    let saved = rig.store.snapshot(&reference());
    assert!(saved.iter().any(|link| link.source.as_str() == "retired"));
}

#[tokio::test]
async fn a_site_without_a_title_match_stays_out_even_when_it_answers() {
    let rig = rig(vec![empty_site("a", 1)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert!(resolved.links.is_empty());
}
