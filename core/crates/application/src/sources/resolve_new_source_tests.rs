use domain::matching::Confidence;
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore};

use super::resolve_support::{empty_site, media, order, reference, rig, site_with};
use crate::matching::MATCHER_VERSION;

const HOUR: u64 = 60 * 60;

fn fresh_link(source: &str, item: &str, checked_at: u64) -> SourceLink {
    let mut link = SourceLink::matched(
        SourceId::new(source),
        ItemId::new(item),
        Confidence::new(0.95),
        checked_at,
    );
    link.matcher_version = MATCHER_VERSION;
    link.unit_count = Some(12);
    link
}

#[tokio::test]
async fn a_site_added_after_the_title_was_linked_is_searched_while_the_old_link_stays() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        site_with("b", 5, "b-spy", 2022, 12),
    ]);
    let old = fresh_link("a", "a-spy", rig.clock_now());
    rig.store.save_all(&reference(), vec![old]).await.unwrap();
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(order(&resolved.links), vec!["a", "b"]);
    assert!(rig.sources[0].calls().is_empty());
    assert!(!rig.sources[1].calls().is_empty());
    assert_eq!(rig.store.snapshot(&reference()).len(), 2);
}

#[tokio::test]
async fn a_site_without_the_title_is_not_searched_on_every_visit() {
    let rig = rig(vec![
        site_with("a", 1, "a-spy", 2022, 12),
        empty_site("b", 5),
    ]);
    rig.use_case.execute(&media()).await.unwrap();
    let searched = rig.sources[1].calls().len();
    assert!(searched > 0);
    rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(rig.sources[1].calls().len(), searched);
    rig.clock.advance(13 * HOUR);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert!(rig.sources[1].calls().len() > searched);
    assert_eq!(order(&resolved.links), vec!["a"]);
}
