use std::sync::Arc;

use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, LinkVariant, SourceId, SourceLink, SourceLinkStore, Unit};
use domain::stream::EpisodeServer;

use super::OpenEpisode;
use crate::ports::SourceProvider;
use crate::sources::{SourceDirectory, SourceHealth};
use crate::testing::{FakeClock, FakeSource, FakeVideo, MemoryLinkStore};

fn reference() -> MediaRef {
    MediaRef::catalog(MediaId::new(140960).unwrap())
}

struct Rig {
    use_case: OpenEpisode<MemoryLinkStore>,
}

fn dubbed_site() -> FakeSource {
    let units = |prefix: &str| vec![Unit::new(format!("{prefix}-ep-1"), 1.0, "Episode 1")];
    let video = FakeVideo::new()
        .with_servers("a-ep-1", vec![EpisodeServer::new("sub-main", "Sub")])
        .with_servers("a-dub-ep-1", vec![EpisodeServer::new("dub-main", "Dub")]);
    FakeSource::new("a", MediaKind::Anime)
        .with_priority(1)
        .with_units("a-item", units("a"))
        .with_units("a-item-dub", units("a-dub"))
        .with_video(video)
}

async fn dubbed_rig() -> Rig {
    let providers: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(dubbed_site())];
    let store = Arc::new(MemoryLinkStore::new());
    let link = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("a-item"),
        Confidence::new(0.9),
        0,
    )
    .with_variants(vec![LinkVariant::new(
        ItemId::new("a-item-dub"),
        "Dub Indonesia",
    )]);
    store.save_all(&reference(), vec![link]).await.unwrap();
    let health = Arc::new(SourceHealth::new(Arc::new(FakeClock::at(0))));
    let directory = Arc::new(SourceDirectory::new(providers));
    Rig {
        use_case: OpenEpisode::new(store, directory, health),
    }
}

#[tokio::test]
async fn the_original_audio_is_played_unless_a_variant_is_asked_for() {
    let rig = dubbed_rig().await;
    let playback = rig
        .use_case
        .execute(&reference(), 1.0, None, &[])
        .await
        .unwrap();
    assert_eq!(playback.item.as_str(), "a-item");
    assert_eq!(playback.audio, None);
    assert_eq!(playback.audio_options, vec!["Dub Indonesia"]);
}

#[tokio::test]
async fn a_requested_dub_opens_the_episode_of_the_twin_entry() {
    let rig = dubbed_rig().await;
    let playback = rig
        .use_case
        .execute_audio(&reference(), 1.0, None, &[], Some("Dub Indonesia"))
        .await
        .unwrap();
    assert_eq!(playback.item.as_str(), "a-item-dub");
    assert_eq!(playback.unit.id, "a-dub-ep-1");
    assert_eq!(playback.audio.as_deref(), Some("Dub Indonesia"));
    assert_eq!(playback.servers[0].id, "dub-main");
}

#[tokio::test]
async fn an_unknown_dub_falls_back_to_the_original_audio() {
    let rig = dubbed_rig().await;
    let playback = rig
        .use_case
        .execute_audio(&reference(), 1.0, None, &[], Some("Dub Inggris"))
        .await
        .unwrap();
    assert_eq!(playback.item.as_str(), "a-item");
    assert_eq!(playback.audio, None);
}
