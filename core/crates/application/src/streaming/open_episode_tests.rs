use std::sync::Arc;

use domain::error::SourceError;
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore, Unit};
use domain::stream::EpisodeServer;

use super::OpenEpisode;
use crate::ports::SourceProvider;
use crate::sources::{SourceDirectory, SourceHealth};
use crate::testing::{FakeClock, FakeSource, FakeVideo, MemoryLinkStore};

fn reference() -> MediaRef {
    MediaRef::catalog(MediaId::new(140960).unwrap())
}

fn site(id: &str, priority: u8, episodes: u32, video: FakeVideo) -> FakeSource {
    let units = (1..=episodes)
        .map(|number| {
            Unit::new(
                format!("{id}-ep-{number}"),
                f64::from(number),
                format!("Episode {number}"),
            )
        })
        .collect();
    FakeSource::new(id, MediaKind::Anime)
        .with_priority(priority)
        .with_units(&format!("{id}-item"), units)
        .with_video(video)
}

fn working_video(id: &str, episodes: u32) -> FakeVideo {
    (1..=episodes).fold(FakeVideo::new(), |video, number| {
        video.with_servers(
            &format!("{id}-ep-{number}"),
            vec![EpisodeServer::new("main", "Main")],
        )
    })
}

struct Rig {
    health: Arc<SourceHealth>,
    use_case: OpenEpisode<MemoryLinkStore>,
}

async fn rig(sites: Vec<FakeSource>) -> Rig {
    let providers: Vec<Arc<dyn SourceProvider>> = sites
        .into_iter()
        .map(|site| Arc::new(site) as Arc<dyn SourceProvider>)
        .collect();
    let store = Arc::new(MemoryLinkStore::new());
    let links: Vec<SourceLink> = providers
        .iter()
        .map(|site| {
            let id = site.info().id.clone();
            let item = ItemId::new(format!("{id}-item"));
            SourceLink::matched(id, item, Confidence::new(0.9), 0)
        })
        .collect();
    store.save_all(&reference(), links).await.unwrap();
    let health = Arc::new(SourceHealth::new(Arc::new(FakeClock::at(0))));
    let directory = Arc::new(SourceDirectory::new(providers));
    let use_case = OpenEpisode::new(store, directory, health.clone());
    Rig { health, use_case }
}

#[tokio::test]
async fn the_best_ranked_site_plays_the_episode() {
    let both = vec![
        site("a", 1, 12, working_video("a", 12)),
        site("b", 5, 12, working_video("b", 12)),
    ];
    let rig = rig(both).await;
    let playback = rig
        .use_case
        .execute(&reference(), 5.0, None, &[])
        .await
        .unwrap();
    assert_eq!(playback.source.as_str(), "a");
    assert_eq!(playback.unit.id, "a-ep-5");
    assert_eq!(playback.servers[0].id, "main");
    assert_eq!(playback.switched_from, None);
}

#[tokio::test]
async fn a_site_whose_servers_all_fail_hands_the_same_episode_to_the_next_site() {
    let broken = working_video("a", 12);
    broken.set_failure(Some(SourceError::Unavailable("down".into())));
    let rig = rig(vec![
        site("a", 1, 12, broken),
        site("b", 5, 12, working_video("b", 12)),
    ])
    .await;
    let playback = rig
        .use_case
        .execute(&reference(), 5.0, None, &[])
        .await
        .unwrap();
    assert_eq!(playback.source.as_str(), "b");
    assert_eq!(playback.unit.id, "b-ep-5");
    assert_eq!(playback.switched_from, Some(SourceId::new("a")));
    assert_eq!(rig.health.recent_failures(&SourceId::new("a")), 1);
}

#[tokio::test]
async fn a_site_without_the_episode_is_passed_over_without_blaming_it() {
    let rig = rig(vec![
        site("a", 1, 4, working_video("a", 4)),
        site("b", 5, 12, working_video("b", 12)),
    ])
    .await;
    let playback = rig
        .use_case
        .execute(&reference(), 9.0, None, &[])
        .await
        .unwrap();
    assert_eq!(playback.source.as_str(), "b");
    assert_eq!(rig.health.recent_failures(&SourceId::new("a")), 0);
}

#[tokio::test]
async fn excluded_sites_are_not_tried_and_a_preferred_site_goes_first() {
    let rig = rig(vec![
        site("a", 1, 12, working_video("a", 12)),
        site("b", 5, 12, working_video("b", 12)),
    ])
    .await;
    let skipped = rig
        .use_case
        .execute(&reference(), 2.0, None, &[SourceId::new("a")])
        .await
        .unwrap();
    assert_eq!(skipped.source.as_str(), "b");
    let wanted = SourceId::new("b");
    let chosen = rig
        .use_case
        .execute(&reference(), 2.0, Some(&wanted), &[])
        .await
        .unwrap();
    assert_eq!(chosen.source.as_str(), "b");
    assert_eq!(chosen.switched_from, None);
}

#[tokio::test]
async fn when_every_site_fails_the_error_is_reported() {
    let broken = working_video("a", 12);
    broken.set_failure(Some(SourceError::Network("offline".into())));
    let rig = rig(vec![site("a", 1, 12, broken)]).await;
    let error = rig
        .use_case
        .execute(&reference(), 1.0, None, &[])
        .await
        .unwrap_err();
    assert_eq!(error, SourceError::Network("offline".into()));
}

#[tokio::test]
async fn a_title_that_only_exists_on_one_site_plays_without_any_stored_link() {
    let only = MediaRef::source(SourceId::new("a"), ItemId::new("a-item"));
    let rig = rig(vec![site("a", 1, 3, working_video("a", 3))]).await;
    let playback = rig.use_case.execute(&only, 2.0, None, &[]).await.unwrap();
    assert_eq!(playback.unit.id, "a-ep-2");
}

#[tokio::test]
async fn an_episode_that_exists_nowhere_is_not_found() {
    let rig = rig(vec![site("a", 1, 3, working_video("a", 3))]).await;
    let error = rig
        .use_case
        .execute(&reference(), 99.0, None, &[])
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::NotFound(_)));
}
