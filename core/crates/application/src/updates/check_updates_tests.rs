use std::sync::Arc;

use domain::library::{FavoriteInput, LibraryRepository};
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore, Unit};

use super::{CheckUpdates, MAX_PER_ROUND};
use crate::ports::{SourceProvider, UpdateLedger};
use crate::sources::{SourceDirectory, SourceHealth};
use crate::testing::{FakeClock, FakeSource, MemoryLibrary, MemoryLinkStore, MemoryUpdateLedger};

fn media(id: u64) -> MediaRef {
    MediaRef::catalog(MediaId::new(id).unwrap())
}

fn units(count: u32) -> Vec<Unit> {
    (1..=count)
        .map(|n| Unit::new(format!("u{n}"), f64::from(n), format!("Ep {n}")))
        .collect()
}

struct Rig {
    library: Arc<MemoryLibrary>,
    links: Arc<MemoryLinkStore>,
    ledger: Arc<MemoryUpdateLedger>,
    clock: Arc<FakeClock>,
    use_case: CheckUpdates<MemoryLibrary, MemoryLinkStore, MemoryUpdateLedger>,
}

fn rig(source: FakeSource) -> Rig {
    let library = Arc::new(MemoryLibrary::new());
    let links = Arc::new(MemoryLinkStore::new());
    let ledger = Arc::new(MemoryUpdateLedger::new());
    let clock = Arc::new(FakeClock::at(1_000));
    let providers: Vec<Arc<dyn SourceProvider>> = vec![Arc::new(source)];
    let use_case = CheckUpdates::new(
        library.clone(),
        links.clone(),
        ledger.clone(),
        Arc::new(SourceDirectory::new(providers)),
        Arc::new(SourceHealth::new(clock.clone())),
        clock.clone(),
    );
    Rig {
        library,
        links,
        ledger,
        clock,
        use_case,
    }
}

async fn favorite(rig: &Rig, id: u64, kind: MediaKind, item: &str) {
    let input = FavoriteInput {
        media: media(id),
        kind,
        title: format!("title {id}"),
        cover_url: None,
    };
    rig.library.toggle_favorite(input).await.unwrap();
    let link = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new(item),
        Confidence::new(0.95),
        0,
    );
    rig.links.save_all(&media(id), vec![link]).await.unwrap();
}

fn source_with(item: &str, count: u32) -> FakeSource {
    FakeSource::new("a", MediaKind::Anime).with_units(item, units(count))
}

#[tokio::test]
async fn the_first_check_only_notes_where_things_stand() {
    let rig = rig(source_with("x", 12));
    favorite(&rig, 1, MediaKind::Anime, "x").await;
    assert!(rig.use_case.execute().await.is_empty());
    let entry = rig.ledger.entry(MediaKind::Anime, &media(1)).unwrap();
    assert_eq!((entry.latest, entry.checked_at), (12.0, 1_000));
}

#[tokio::test]
async fn a_new_episode_after_the_baseline_is_reported_once() {
    let rig = rig(source_with("x", 13));
    favorite(&rig, 1, MediaKind::Anime, "x").await;
    rig.ledger
        .record(MediaKind::Anime, &media(1), 12.0, 10)
        .await
        .unwrap();
    let events = rig.use_case.execute().await;
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].unit_number, 13.0);
    assert_eq!(events[0].previous, 12.0);
    assert_eq!(events[0].title, "title 1");
    rig.clock.advance(7_200);
    assert!(rig.use_case.execute().await.is_empty());
}

#[tokio::test]
async fn nothing_new_means_no_event() {
    let rig = rig(source_with("x", 12));
    favorite(&rig, 1, MediaKind::Anime, "x").await;
    rig.ledger
        .record(MediaKind::Anime, &media(1), 12.0, 10)
        .await
        .unwrap();
    assert!(rig.use_case.execute().await.is_empty());
}

#[tokio::test]
async fn a_favourite_whose_site_fails_is_skipped_and_the_others_still_count() {
    let rig = rig(source_with("good", 5));
    favorite(&rig, 1, MediaKind::Anime, "missing").await;
    favorite(&rig, 2, MediaKind::Anime, "good").await;
    rig.ledger
        .record(MediaKind::Anime, &media(2), 4.0, 10)
        .await
        .unwrap();
    let events = rig.use_case.execute().await;
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].media, media(2));
    assert!(rig.ledger.entry(MediaKind::Anime, &media(1)).is_none());
}

#[tokio::test]
async fn a_favourite_with_no_link_is_left_alone() {
    let rig = rig(source_with("x", 5));
    let input = FavoriteInput {
        media: media(9),
        kind: MediaKind::Manga,
        title: "unlinked".into(),
        cover_url: None,
    };
    rig.library.toggle_favorite(input).await.unwrap();
    assert!(rig.use_case.execute().await.is_empty());
}

#[tokio::test]
async fn at_most_thirty_titles_are_checked_in_a_round_oldest_first() {
    let rig = rig(source_with("x", 5));
    for id in 1..=(MAX_PER_ROUND as u64 + 5) {
        favorite(&rig, id, MediaKind::Anime, "x").await;
        rig.ledger
            .record(MediaKind::Anime, &media(id), 5.0, id)
            .await
            .unwrap();
    }
    rig.use_case.execute().await;
    let refreshed = (1..=(MAX_PER_ROUND as u64 + 5))
        .filter(|id| {
            rig.ledger
                .entry(MediaKind::Anime, &media(*id))
                .unwrap()
                .checked_at
                == 1_000
        })
        .count();
    assert_eq!(refreshed, MAX_PER_ROUND);
    let skipped = rig
        .ledger
        .entry(MediaKind::Anime, &media(MAX_PER_ROUND as u64 + 5));
    assert_eq!(skipped.unwrap().checked_at, MAX_PER_ROUND as u64 + 5);
}
