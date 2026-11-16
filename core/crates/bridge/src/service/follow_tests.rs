use application::testing::FakeSource;
use domain::library::{FavoriteInput, LibraryRepository};
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore, Unit};
use std::sync::Arc;

use super::follow::check_followed;
use super::service_support::{Folder, offline, state_with};
use application::ports::SourceProvider;

fn media() -> MediaRef {
    MediaRef::catalog(MediaId::new(7).unwrap())
}

fn source(count: u32) -> Arc<dyn SourceProvider> {
    let units = (1..=count)
        .map(|n| Unit::new(format!("u{n}"), f64::from(n), format!("Ep {n}")))
        .collect();
    Arc::new(FakeSource::new("a", MediaKind::Anime).with_units("a-show", units))
}

#[tokio::test]
async fn the_first_round_is_quiet_and_a_later_round_with_a_new_episode_reports_it() {
    let folder = Folder::new();
    let state = state_with(&folder, vec![source(3)], offline()).await;
    let input = FavoriteInput {
        media: media(),
        kind: MediaKind::Anime,
        title: "Show".into(),
        cover_url: None,
    };
    state.library.toggle_favorite(input).await.unwrap();
    let link = SourceLink::matched(
        SourceId::new("a"),
        ItemId::new("a-show"),
        Confidence::new(0.95),
        0,
    );
    state.links.save_all(&media(), vec![link]).await.unwrap();
    assert!(check_followed(&state).await.is_empty());
    drop(state);

    let state = state_with(&folder, vec![source(4)], offline()).await;
    let events = check_followed(&state).await;
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].title, "Show");
    assert_eq!(events[0].unit_number, 4.0);
    assert_eq!(events[0].previous, 3.0);
    assert!(check_followed(&state).await.is_empty());
}
