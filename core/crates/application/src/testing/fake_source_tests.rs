use domain::error::SourceError;
use domain::media::MediaKind;
use domain::source::{ItemId, SourceItem, SourceSearch, StreamSupport};

use super::{FakeSource, FakeVideo};
use crate::ports::SourceProvider;

fn item(id: &str, title: &str) -> SourceItem {
    SourceItem::new(ItemId::new(id), title)
}

#[tokio::test]
async fn search_ignores_case_and_surrounding_spaces() {
    let source = FakeSource::new("a", MediaKind::Anime)
        .with_search("Kimi No Na Wa", vec![item("1", "Kimi no Na wa.")]);
    let page = source
        .search(SourceSearch::new("  kimi no na wa "))
        .await
        .unwrap();
    assert_eq!(page.items.len(), 1);
    let none = source.search(SourceSearch::new("other")).await.unwrap();
    assert!(none.items.is_empty());
}

#[tokio::test]
async fn detail_and_units_are_not_found_when_unknown() {
    let source = FakeSource::new("a", MediaKind::Anime);
    assert!(matches!(
        source.detail(ItemId::new("x")).await,
        Err(SourceError::NotFound(_))
    ));
    assert!(matches!(
        source.units(ItemId::new("x")).await,
        Err(SourceError::NotFound(_))
    ));
}

#[tokio::test]
async fn failure_can_be_switched_on_and_off_and_calls_are_recorded() {
    let source = FakeSource::new("a", MediaKind::Manga);
    source.set_failure(Some(SourceError::Network("down".into())));
    assert!(source.latest(1).await.is_err());
    source.set_failure(None);
    assert!(source.latest(2).await.is_ok());
    assert_eq!(
        source.calls(),
        vec!["latest 1".to_string(), "latest 2".to_string()]
    );
}

#[test]
fn video_makes_the_source_stream_capable() {
    let plain = FakeSource::new("a", MediaKind::Anime);
    assert!(plain.video().is_none());
    let streaming = FakeSource::new("b", MediaKind::Anime).with_video(FakeVideo::new());
    assert!(streaming.video().is_some());
    assert_eq!(streaming.info().capabilities.stream, StreamSupport::Direct);
}

#[test]
fn priority_can_be_overridden() {
    let source = FakeSource::new("a", MediaKind::Anime).with_priority(9);
    assert_eq!(source.info().priority, 9);
}
