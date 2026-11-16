use domain::media::{MediaFormat, MediaId, MediaKind, MediaStatus, MediaSummary, MediaTitle};
use domain::source::{ItemId, SourceDetail, SourceItem};

use super::resolve_support::rig;
use crate::testing::FakeSource;

fn item(key: &str, title: &str) -> SourceItem {
    SourceItem::new(ItemId::new(key), title)
}

fn detail(key: &str, title: &str, kind: &str, year: u16, units: u32) -> SourceDetail {
    let mut detail = SourceDetail::new(item(key, title));
    detail.type_text = Some(kind.into());
    detail.year = Some(year);
    detail.unit_count = Some(units);
    detail
}

fn kimetsu() -> MediaSummary {
    let mut media = MediaSummary::new(
        MediaId::new(101922).unwrap(),
        MediaKind::Anime,
        MediaTitle::new("Kimetsu no Yaiba"),
    );
    media.format = Some(MediaFormat::Tv);
    media.year = Some(2019);
    media.unit_count = Some(26);
    media.status = Some(MediaStatus::Finished);
    media
}

fn unreleased_movie() -> MediaSummary {
    let mut media = MediaSummary::new(
        MediaId::new(195201).unwrap(),
        MediaKind::Anime,
        MediaTitle::new("Kimetsu no Yaiba: Mugenjou-hen Movie 3"),
    );
    media.format = Some(MediaFormat::Movie);
    media.unit_count = Some(1);
    media.status = Some(MediaStatus::NotYetReleased);
    media
}

fn twins_site(dub_first: bool) -> FakeSource {
    let plain = item("280/kimetsu-no-yaiba", "Kimetsu no Yaiba");
    let dub = item("2120/kimetsu-no-yaiba-dub-id", "Kimetsu no Yaiba (Dub ID)");
    let listing = if dub_first {
        vec![dub, plain]
    } else {
        vec![plain, dub]
    };
    FakeSource::new("a", MediaKind::Anime)
        .with_search("Kimetsu no Yaiba", listing)
        .with_detail(detail(
            "280/kimetsu-no-yaiba",
            "Kimetsu no Yaiba",
            "TV",
            2019,
            26,
        ))
        .with_detail(detail(
            "2120/kimetsu-no-yaiba-dub-id",
            "Kimetsu no Yaiba (Dub ID)",
            "TV",
            2019,
            26,
        ))
}

#[tokio::test]
async fn the_plain_entry_is_the_link_and_the_dub_twin_is_its_variant() {
    for dub_first in [true, false] {
        let rig = rig(vec![twins_site(dub_first)]);
        let resolved = rig.use_case.execute(&kimetsu()).await.unwrap();
        let link = resolved.best().unwrap();
        assert_eq!(link.item.as_str(), "280/kimetsu-no-yaiba");
        assert_eq!(link.title.as_deref(), Some("Kimetsu no Yaiba"));
        assert_eq!(link.variants.len(), 1);
        assert_eq!(
            link.variants[0].item.as_str(),
            "2120/kimetsu-no-yaiba-dub-id"
        );
        assert_eq!(link.variants[0].audio, "Dub Indonesia");
    }
}

#[tokio::test]
async fn a_film_that_has_not_aired_is_not_linked_to_another_film() {
    let mugen_train = "Demon Slayer: Kimetsu no Yaiba - The Movie: Mugen Train";
    let site = FakeSource::new("a", MediaKind::Anime)
        .with_search(
            "Kimetsu no Yaiba: Mugenjou-hen Movie 3",
            vec![item("mugen-train", mugen_train)],
        )
        .with_detail(detail("mugen-train", mugen_train, "Movie", 2020, 1));
    let rig = rig(vec![site]);
    let resolved = rig.use_case.execute(&unreleased_movie()).await.unwrap();
    assert!(resolved.links.is_empty());
}

#[tokio::test]
async fn the_mal_number_links_a_site_whose_title_is_not_in_any_catalog_title() {
    let mut known = detail("rascal", "Totally Different Site Name", "TV", 2025, 13);
    known.mal_id = Some(61469);
    let site = FakeSource::new("a", MediaKind::Anime)
        .with_search("Kimetsu no Yaiba", vec![item("rascal", "Kimetsu no Yaiba")])
        .with_detail(known);
    let mut media = kimetsu();
    media.id_mal = Some(61469);
    let resolved = rig(vec![site]).use_case.execute(&media).await.unwrap();
    assert_eq!(resolved.best().unwrap().item.as_str(), "rascal");
}

#[tokio::test]
async fn another_mal_number_is_refused_even_with_the_same_title() {
    let mut known = detail("other", "Kimetsu no Yaiba", "TV", 2019, 26);
    known.mal_id = Some(5);
    let site = FakeSource::new("a", MediaKind::Anime)
        .with_search("Kimetsu no Yaiba", vec![item("other", "Kimetsu no Yaiba")])
        .with_detail(known);
    let mut media = kimetsu();
    media.id_mal = Some(38000);
    let resolved = rig(vec![site]).use_case.execute(&media).await.unwrap();
    assert!(resolved.links.is_empty());
}
