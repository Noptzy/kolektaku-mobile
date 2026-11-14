use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{
    EpisodeInfo, MediaDetail, MediaFormat, MediaId, MediaKind, MediaRef, MediaStatus, MediaSummary,
    MediaTitle,
};
use domain::source::{ItemId, SourceDetail, SourceId, SourceItem, Unit};

use super::{ListUnits, MediaView, MediaViewer};
use crate::ports::SourceProvider;
use crate::sources::{ResolveSources, SourceDirectory, SourceHealth};
use crate::testing::{FakeCatalog, FakeClock, FakeSource, MemoryLinkStore};

const TITLE: &str = "Spy x Family";

fn summary() -> MediaSummary {
    let mut media = MediaSummary::new(
        MediaId::new(140960).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(TITLE),
    );
    media.format = Some(MediaFormat::Tv);
    media.year = Some(2022);
    media.unit_count = Some(12);
    media.status = Some(MediaStatus::Finished);
    media
}

fn site() -> FakeSource {
    let mut detail = SourceDetail::new(SourceItem::new(ItemId::new("a-spy"), TITLE));
    detail.type_text = Some("TV".into());
    detail.year = Some(2022);
    detail.unit_count = Some(12);
    FakeSource::new("a", MediaKind::Anime)
        .with_search(TITLE, vec![SourceItem::new(ItemId::new("a-spy"), TITLE)])
        .with_detail(detail)
        .with_units(
            "a-spy",
            vec![
                Unit::new("a-ep-1", 1.0, "Episode 1"),
                Unit::new("a-ep-2", 2.0, "Episode 2"),
            ],
        )
}

struct Rig {
    viewer: MediaViewer<FakeCatalog, MemoryLinkStore>,
    units: ListUnits<MemoryLinkStore>,
    health: Arc<SourceHealth>,
}

fn rig(catalog: FakeCatalog, source: FakeSource) -> Rig {
    let providers: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(source)];
    let store = Arc::new(MemoryLinkStore::new());
    let clock = Arc::new(FakeClock::at(1_000));
    let health = Arc::new(SourceHealth::new(clock.clone()));
    let resolver = Arc::new(ResolveSources::new(
        providers.clone(),
        store.clone(),
        health.clone(),
        clock,
    ));
    let directory = Arc::new(SourceDirectory::new(providers));
    Rig {
        viewer: MediaViewer::new(Arc::new(catalog), resolver, directory.clone()),
        units: ListUnits::new(store, directory, health.clone()),
        health,
    }
}

fn catalog_with_detail() -> FakeCatalog {
    FakeCatalog::new().with_detail(MediaDetail::new(summary()))
}

#[tokio::test]
async fn a_catalog_title_opens_with_its_data_and_its_resolved_sources() {
    let rig = rig(catalog_with_detail(), site());
    let reference = MediaRef::catalog(summary().id);
    let MediaView::Catalog(view) = rig
        .viewer
        .execute(MediaKind::Anime, &reference)
        .await
        .unwrap()
    else {
        panic!("expected a catalog view");
    };
    assert_eq!(view.detail.summary.title.romaji, TITLE);
    assert_eq!(view.sources.links.len(), 1);
    assert!(view.resolve_error.is_none());
}

#[tokio::test]
async fn the_detail_still_opens_when_the_sites_cannot_be_asked() {
    let down = site().failing_with(SourceError::Unavailable("down".into()));
    let rig = rig(catalog_with_detail(), down);
    let reference = MediaRef::catalog(summary().id);
    let MediaView::Catalog(view) = rig
        .viewer
        .execute(MediaKind::Anime, &reference)
        .await
        .unwrap()
    else {
        panic!("expected a catalog view");
    };
    assert!(view.sources.links.is_empty());
    assert!(matches!(
        view.resolve_error,
        Some(SourceError::Unavailable(_))
    ));
}

#[tokio::test]
async fn a_title_unknown_to_the_catalog_is_an_error() {
    let rig = rig(FakeCatalog::new(), site());
    let error = rig
        .viewer
        .execute(MediaKind::Anime, &MediaRef::catalog(summary().id))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::NotFound(_)));
}

#[tokio::test]
async fn a_site_only_title_opens_with_limited_site_data() {
    let rig = rig(FakeCatalog::new(), site());
    let reference = MediaRef::source(SourceId::new("a"), ItemId::new("a-spy"));
    let MediaView::Site(view) = rig
        .viewer
        .execute(MediaKind::Anime, &reference)
        .await
        .unwrap()
    else {
        panic!("expected a site view");
    };
    assert_eq!(view.detail.item.title, TITLE);
    assert_eq!(view.source.as_str(), "a");
}

#[tokio::test]
async fn units_come_from_the_resolved_source() {
    let rig = rig(catalog_with_detail(), site());
    let reference = MediaRef::catalog(summary().id);
    rig.viewer
        .execute(MediaKind::Anime, &reference)
        .await
        .unwrap();
    let view = rig.units.execute(&reference, None).await.unwrap();
    assert_eq!(view.source.as_str(), "a");
    assert_eq!(view.units.len(), 2);
}

#[tokio::test]
async fn units_of_a_site_only_title_need_no_stored_link() {
    let rig = rig(FakeCatalog::new(), site());
    let reference = MediaRef::source(SourceId::new("a"), ItemId::new("a-spy"));
    assert_eq!(
        rig.units
            .execute(&reference, None)
            .await
            .unwrap()
            .units
            .len(),
        2
    );
}

#[tokio::test]
async fn asking_for_a_source_that_has_no_link_is_not_found() {
    let rig = rig(catalog_with_detail(), site());
    let reference = MediaRef::catalog(summary().id);
    rig.viewer
        .execute(MediaKind::Anime, &reference)
        .await
        .unwrap();
    let other = SourceId::new("elsewhere");
    let error = rig
        .units
        .execute(&reference, Some(&other))
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::NotFound(_)));
}

#[tokio::test]
async fn a_failing_units_request_counts_against_the_site() {
    let broken = site().failing_with(SourceError::Unavailable("down".into()));
    let rig = rig(catalog_with_detail(), broken);
    let reference = MediaRef::source(SourceId::new("a"), ItemId::new("a-spy"));
    assert!(rig.units.execute(&reference, None).await.is_err());
    assert_eq!(rig.health.recent_failures(&SourceId::new("a")), 1);
}

#[tokio::test]
async fn episode_titles_from_the_catalog_end_up_in_the_view() {
    let media = summary();
    let id = media.id;
    let catalog = FakeCatalog::new()
        .with_detail(MediaDetail::new(media))
        .with_episode_titles(id, vec![EpisodeInfo::new(1.0, "Operation Strix")]);
    let rig = rig(catalog, site());
    let view = rig
        .viewer
        .execute(MediaKind::Anime, &MediaRef::catalog(id))
        .await
        .unwrap();
    let MediaView::Catalog(catalog_view) = view else {
        panic!("expected a catalog view");
    };
    assert_eq!(catalog_view.detail.episodes[0].title, "Operation Strix");
    assert!(!catalog_view.sources.links.is_empty());
}
