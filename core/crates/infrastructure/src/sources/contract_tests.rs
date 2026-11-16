use domain::media::MediaKind;
use domain::source::{ItemId, SourceSearch, StreamSupport};

use super::contract::{each_site, serving, source_over};
use super::registry::REGISTRATIONS;

#[test]
fn the_registry_has_unique_ids_and_the_real_sites() {
    let ids: Vec<&str> = REGISTRATIONS.iter().map(|item| item.defaults.id).collect();
    let mut unique = ids.clone();
    unique.sort_unstable();
    unique.dedup();
    assert_eq!(unique.len(), ids.len());
    for real in [
        "kuramanime",
        "komiku",
        "komikindo",
        "meionovels",
        "novelphoenix",
        "weebcentral",
    ] {
        assert!(ids.contains(&real), "{real}");
    }
}

#[test]
fn every_source_describes_itself_consistently() {
    for (registration, site) in each_site() {
        let source = source_over(registration, serving(&site));
        let info = source.info();
        let id = registration.defaults.id;
        assert_eq!(info.id.as_str(), id);
        assert!(!info.name.trim().is_empty(), "{id}");
        assert_eq!(info.priority, registration.defaults.priority, "{id}");
        assert_eq!(
            source.video().is_some(),
            info.capabilities.stream != StreamSupport::None,
            "{id}"
        );
        assert_eq!(
            source.pages().is_some(),
            info.kind == MediaKind::Manga,
            "{id}"
        );
        assert_eq!(
            source.texts().is_some(),
            info.kind == MediaKind::Novel,
            "{id}"
        );
    }
}

#[tokio::test]
async fn search_finds_the_known_item_and_every_result_is_well_formed() {
    for (registration, site) in each_site() {
        let source = source_over(registration, serving(&site));
        let page = source
            .search(SourceSearch::new(site.search_query))
            .await
            .unwrap();
        let id = registration.defaults.id;
        assert!(
            page.items
                .iter()
                .any(|item| item.item_id.as_str() == site.item_id),
            "{id}"
        );
        for item in &page.items {
            assert!(
                !item.title.trim().is_empty() && !item.item_id.as_str().is_empty(),
                "{id}"
            );
        }
    }
}

#[tokio::test]
async fn latest_lists_items() {
    for (registration, site) in each_site() {
        let source = source_over(registration, serving(&site));
        let page = source.latest(1).await.unwrap();
        assert!(!page.items.is_empty(), "{}", registration.defaults.id);
        assert!(page.page == 1 && page.total_pages >= 1);
    }
}

#[tokio::test]
async fn detail_matches_the_requested_item() {
    for (registration, site) in each_site() {
        let source = source_over(registration, serving(&site));
        let detail = source.detail(ItemId::new(site.item_id)).await.unwrap();
        assert_eq!(detail.item.item_id.as_str(), site.item_id);
        assert!(
            !detail.item.title.trim().is_empty(),
            "{}",
            registration.defaults.id
        );
    }
}

#[tokio::test]
async fn units_are_not_empty_sorted_and_unique() {
    for (registration, site) in each_site() {
        let source = source_over(registration, serving(&site));
        let units = source.units(ItemId::new(site.item_id)).await.unwrap();
        let id = registration.defaults.id;
        assert!(units.len() >= site.min_units, "{id}");
        assert!(
            units
                .windows(2)
                .all(|pair| pair[0].number <= pair[1].number),
            "{id}"
        );
        let mut ids: Vec<&str> = units.iter().map(|unit| unit.id.as_str()).collect();
        ids.sort_unstable();
        ids.dedup();
        assert_eq!(ids.len(), units.len(), "{id}");
    }
}
