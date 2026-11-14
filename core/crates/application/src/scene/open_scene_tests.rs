use std::sync::Arc;

use domain::error::SourceError;
use domain::media::{MediaDetail, MediaFormat, MediaId, MediaKind, MediaSummary, MediaTitle};
use domain::scene::SceneMatch;
use domain::source::{ItemId, SourceDetail, SourceItem, Unit};

use super::{DetailReason, OpenScene, SceneTarget};
use crate::detail::MediaViewer;
use crate::ports::SourceProvider;
use crate::sources::{ResolveSources, SourceDirectory, SourceHealth};
use crate::testing::{FakeCatalog, FakeClock, FakeSource, MemoryLinkStore};

const TITLE: &str = "Gochuumon wa Usagi desu ka";
const ID: u64 = 21034;

fn summary(format: MediaFormat) -> MediaSummary {
    let mut media = MediaSummary::new(
        MediaId::new(ID).unwrap(),
        MediaKind::Anime,
        MediaTitle::new(TITLE),
    );
    media.format = Some(format);
    media.year = Some(2015);
    media.unit_count = Some(12);
    media
}

fn source_with_title() -> FakeSource {
    let mut detail = SourceDetail::new(SourceItem::new(ItemId::new("a-usagi"), TITLE));
    detail.year = Some(2015);
    detail.unit_count = Some(12);
    FakeSource::new("a", MediaKind::Anime)
        .with_search(TITLE, vec![SourceItem::new(ItemId::new("a-usagi"), TITLE)])
        .with_detail(detail)
        .with_units("a-usagi", vec![Unit::new("a-ep-1", 1.0, "Episode 1")])
}

fn empty_source() -> FakeSource {
    FakeSource::new("a", MediaKind::Anime)
}

fn opener(catalog: FakeCatalog, source: FakeSource) -> OpenScene<FakeCatalog, MemoryLinkStore> {
    let providers: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(source)];
    let store = Arc::new(MemoryLinkStore::new());
    let clock = Arc::new(FakeClock::at(1_000));
    let health = Arc::new(SourceHealth::new(clock.clone()));
    let resolver = Arc::new(ResolveSources::new(providers.clone(), store, health, clock));
    let directory = Arc::new(SourceDirectory::new(providers));
    OpenScene::new(Arc::new(MediaViewer::new(
        Arc::new(catalog),
        resolver,
        directory,
    )))
}

fn catalog(format: MediaFormat) -> FakeCatalog {
    FakeCatalog::new().with_detail(MediaDetail::new(summary(format)))
}

fn scene(episode: Option<f64>, at_secs: f64) -> SceneMatch {
    SceneMatch {
        media_id: MediaId::new(ID).unwrap(),
        episode,
        from_secs: at_secs - 2.0,
        at_secs,
        to_secs: at_secs + 3.0,
        similarity: 0.99,
        preview_image_url: None,
        title: None,
        is_adult: false,
        duration_secs: Some(1418.0),
    }
}

#[tokio::test]
async fn a_known_episode_opens_the_player_three_seconds_early() {
    let target = opener(catalog(MediaFormat::Tv), source_with_title())
        .execute(&scene(Some(1.0), 279.78))
        .await
        .unwrap();
    assert_eq!(
        target,
        SceneTarget::Watch {
            media: MediaId::new(ID).unwrap(),
            episode: 1.0,
            start_secs: 279.78 - 3.0,
            duration_secs: Some(1418.0),
        }
    );
}

#[tokio::test]
async fn the_start_never_goes_before_the_beginning() {
    let target = opener(catalog(MediaFormat::Tv), source_with_title())
        .execute(&scene(Some(2.0), 1.5))
        .await
        .unwrap();
    let SceneTarget::Watch { start_secs, .. } = target else {
        panic!("expected the player");
    };
    assert_eq!(start_secs, 0.0);
}

#[tokio::test]
async fn a_film_without_an_episode_number_is_episode_one() {
    let target = opener(catalog(MediaFormat::Movie), source_with_title())
        .execute(&scene(None, 600.0))
        .await
        .unwrap();
    let SceneTarget::Watch { episode, .. } = target else {
        panic!("expected the player");
    };
    assert_eq!(episode, 1.0);
}

#[tokio::test]
async fn a_series_without_an_episode_number_opens_the_detail_page() {
    let target = opener(catalog(MediaFormat::Tv), source_with_title())
        .execute(&scene(None, 600.0))
        .await
        .unwrap();
    assert_eq!(
        target,
        SceneTarget::Detail {
            media: MediaId::new(ID).unwrap(),
            reason: DetailReason::NoEpisode,
        }
    );
}

#[tokio::test]
async fn a_title_no_source_has_opens_the_detail_page_with_a_note() {
    let target = opener(catalog(MediaFormat::Tv), empty_source())
        .execute(&scene(Some(1.0), 100.0))
        .await
        .unwrap();
    assert_eq!(
        target,
        SceneTarget::Detail {
            media: MediaId::new(ID).unwrap(),
            reason: DetailReason::NotAvailable,
        }
    );
}

#[tokio::test]
async fn a_catalog_failure_is_reported_not_hidden() {
    let failing = catalog(MediaFormat::Tv).failing_with(SourceError::Network("offline".into()));
    let result = opener(failing, source_with_title())
        .execute(&scene(Some(1.0), 100.0))
        .await;
    assert_eq!(result, Err(SourceError::Network("offline".into())));
}

#[tokio::test]
async fn sources_that_fail_are_reported_instead_of_claiming_nothing_exists() {
    let broken = FakeSource::new("a", MediaKind::Anime)
        .failing_with(SourceError::Unavailable("down".into()));
    let result = opener(catalog(MediaFormat::Tv), broken)
        .execute(&scene(Some(1.0), 100.0))
        .await;
    assert_eq!(result, Err(SourceError::Unavailable("down".into())));
}
