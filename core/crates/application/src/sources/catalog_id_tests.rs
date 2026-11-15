use domain::media::MediaKind;
use domain::source::{ItemId, SourceItem};

use super::resolve_support::{TITLE, detail, media, rig};
use crate::testing::FakeSource;

const CATALOG_ID: u64 = 140960;

fn site(id: &str, item: &str, catalog_id: Option<u64>, year: u16) -> FakeSource {
    let mut known = detail(item, TITLE, year, 12);
    known.catalog_id = catalog_id;
    FakeSource::new(id, MediaKind::Anime)
        .with_search(TITLE, vec![SourceItem::new(ItemId::new(item), TITLE)])
        .with_detail(known)
}

#[tokio::test]
async fn a_site_naming_the_same_catalog_number_is_a_certain_match_even_when_the_facts_differ() {
    let rig = rig(vec![site("a", "a-spy", Some(CATALOG_ID), 1999)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    let best = resolved.best().unwrap();
    assert_eq!(best.item.as_str(), "a-spy");
    assert!(best.confidence.is_automatic());
    assert!(best.confidence.get() >= 1.0 - f32::EPSILON);
}

#[tokio::test]
async fn a_site_naming_another_catalog_number_is_refused_even_with_an_identical_title() {
    let rig = rig(vec![site("a", "a-spy", Some(CATALOG_ID + 1), 2022)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert!(resolved.links.is_empty());
}

#[tokio::test]
async fn a_site_without_a_catalog_number_is_judged_by_its_facts_as_before() {
    let rig = rig(vec![site("a", "a-spy", None, 2022)]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(resolved.best().unwrap().item.as_str(), "a-spy");
}

#[tokio::test]
async fn the_candidate_with_the_right_number_wins_over_a_better_looking_wrong_one() {
    let mut right = detail("a-right", TITLE, 1999, 12);
    right.catalog_id = Some(CATALOG_ID);
    let mut wrong = detail("a-wrong", TITLE, 2022, 12);
    wrong.catalog_id = Some(CATALOG_ID + 7);
    let source = FakeSource::new("a", MediaKind::Anime)
        .with_search(
            TITLE,
            vec![
                SourceItem::new(ItemId::new("a-wrong"), TITLE),
                SourceItem::new(ItemId::new("a-right"), TITLE),
            ],
        )
        .with_detail(right)
        .with_detail(wrong);
    let rig = rig(vec![source]);
    let resolved = rig.use_case.execute(&media()).await.unwrap();
    assert_eq!(resolved.best().unwrap().item.as_str(), "a-right");
}
