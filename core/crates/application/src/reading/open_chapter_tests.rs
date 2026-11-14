use std::sync::Arc;

use domain::error::SourceError;
use domain::matching::Confidence;
use domain::media::{MediaId, MediaKind, MediaRef};
use domain::source::{ItemId, SourceId, SourceLink, SourceLinkStore, Unit};

use super::OpenChapter;
use crate::ports::SourceProvider;
use crate::sources::{SourceDirectory, SourceHealth};
use crate::testing::{FakeClock, FakePages, FakeSource, MemoryLinkStore};

fn reference() -> MediaRef {
    MediaRef::catalog(MediaId::new(30013).unwrap())
}

fn site(id: &str, priority: u8, chapters: u32, pages: FakePages) -> FakeSource {
    let units = (1..=chapters)
        .map(|number| {
            Unit::new(
                format!("{id}-ch-{number}"),
                f64::from(number),
                format!("Chapter {number}"),
            )
        })
        .collect();
    FakeSource::new(id, MediaKind::Manga)
        .with_priority(priority)
        .with_units(&format!("{id}-item"), units)
        .with_pages(pages)
}

fn pages_for(id: &str, chapters: u32) -> FakePages {
    (1..=chapters).fold(FakePages::new(), |pages, number| {
        pages.with_chapter(
            &format!("{id}-ch-{number}"),
            &["https://img.test/1.jpg", "https://img.test/2.jpg"],
        )
    })
}

async fn rig(sites: Vec<FakeSource>) -> (OpenChapter<MemoryLinkStore>, Arc<SourceHealth>) {
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
    (OpenChapter::new(store, directory, health.clone()), health)
}

#[tokio::test]
async fn the_best_site_serves_the_chapter_images() {
    let (use_case, _) = rig(vec![
        site("a", 1, 10, pages_for("a", 10)),
        site("b", 5, 10, pages_for("b", 10)),
    ])
    .await;
    let view = use_case
        .execute(&reference(), 3.0, None, &[])
        .await
        .unwrap();
    assert_eq!(view.source.as_str(), "a");
    assert_eq!(view.unit.id, "a-ch-3");
    assert_eq!(view.pages.pages.len(), 2);
    assert_eq!(view.switched_from, None);
}

#[tokio::test]
async fn a_site_that_cannot_load_the_images_hands_over_to_the_next() {
    let broken = pages_for("a", 10);
    broken.set_failure(Some(SourceError::Unavailable("down".into())));
    let (use_case, health) = rig(vec![
        site("a", 1, 10, broken),
        site("b", 5, 10, pages_for("b", 10)),
    ])
    .await;
    let view = use_case
        .execute(&reference(), 3.0, None, &[])
        .await
        .unwrap();
    assert_eq!(view.source.as_str(), "b");
    assert_eq!(view.switched_from, Some(SourceId::new("a")));
    assert_eq!(health.recent_failures(&SourceId::new("a")), 1);
}

#[tokio::test]
async fn a_chapter_that_no_site_has_is_not_found() {
    let (use_case, _) = rig(vec![site("a", 1, 2, pages_for("a", 2))]).await;
    let error = use_case
        .execute(&reference(), 50.0, None, &[])
        .await
        .unwrap_err();
    assert!(matches!(error, SourceError::NotFound(_)));
}

#[tokio::test]
async fn half_chapters_are_addressable() {
    let units = vec![Unit::new("a-ch-10-5", 10.5, "Chapter 10.5")];
    let source = FakeSource::new("a", MediaKind::Manga)
        .with_units("a-item", units)
        .with_pages(FakePages::new().with_chapter("a-ch-10-5", &["https://img.test/1.jpg"]));
    let (use_case, _) = rig(vec![source]).await;
    let view = use_case
        .execute(&reference(), 10.5, None, &[])
        .await
        .unwrap();
    assert_eq!(view.unit.id, "a-ch-10-5");
}
