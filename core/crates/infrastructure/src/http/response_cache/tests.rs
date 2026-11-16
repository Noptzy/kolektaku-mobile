use application::testing::FakeClock;

use super::*;
use crate::storage::TempFolder;

fn cache_in(folder: &TempFolder, clock: Arc<FakeClock>, capacity: usize) -> ResponseCache {
    ResponseCache::new(folder.file("cache"), clock, capacity)
}

#[tokio::test]
async fn a_stored_body_comes_back_with_its_age() {
    let folder = TempFolder::new("rc-age");
    let clock = Arc::new(FakeClock::at(1000));
    let cache = cache_in(&folder, clock.clone(), 10);
    cache.store("k", "{\"a\":1}\nline two").await;
    clock.advance(42);
    let hit = cache.lookup("k").await.unwrap();
    assert_eq!(hit.body, "{\"a\":1}\nline two");
    assert_eq!(hit.age_secs, 42);
}

#[tokio::test]
async fn an_unknown_key_is_a_miss() {
    let folder = TempFolder::new("rc-miss");
    let cache = cache_in(&folder, Arc::new(FakeClock::at(1)), 10);
    assert_eq!(cache.lookup("nothing").await, None);
}

#[tokio::test]
async fn storing_again_replaces_the_body_and_resets_the_age() {
    let folder = TempFolder::new("rc-replace");
    let clock = Arc::new(FakeClock::at(10));
    let cache = cache_in(&folder, clock.clone(), 10);
    cache.store("k", "old").await;
    clock.advance(500);
    cache.store("k", "new").await;
    let hit = cache.lookup("k").await.unwrap();
    assert_eq!((hit.body.as_str(), hit.age_secs), ("new", 0));
}

#[tokio::test]
async fn clear_forgets_everything() {
    let folder = TempFolder::new("rc-clear");
    let cache = cache_in(&folder, Arc::new(FakeClock::at(1)), 10);
    cache.store("a", "1").await;
    cache.store("b", "2").await;
    cache.clear().await;
    assert_eq!(cache.lookup("a").await, None);
    assert_eq!(cache.lookup("b").await, None);
}

#[tokio::test]
async fn prune_keeps_only_the_newest_up_to_capacity() {
    let folder = TempFolder::new("rc-prune");
    let cache = cache_in(&folder, Arc::new(FakeClock::at(1)), 2);
    for key in ["a", "b", "c", "d", "e"] {
        cache.store(key, key).await;
    }
    cache.prune().await;
    assert_eq!(cache.files().await.len(), 2);
}

#[tokio::test]
async fn a_damaged_file_is_a_miss_not_a_crash() {
    let folder = TempFolder::new("rc-damaged");
    let cache = cache_in(&folder, Arc::new(FakeClock::at(1)), 10);
    cache.store("k", "fine").await;
    let file = cache.file_of("k");
    tokio::fs::write(&file, "no newline here").await.unwrap();
    assert_eq!(cache.lookup("k").await, None);
}

#[test]
fn different_keys_get_different_files() {
    let folder = TempFolder::new("rc-names");
    let cache = cache_in(&folder, Arc::new(FakeClock::at(1)), 10);
    assert_ne!(cache.file_of("a"), cache.file_of("b"));
    assert_eq!(cache.file_of("a"), cache.file_of("a"));
}
