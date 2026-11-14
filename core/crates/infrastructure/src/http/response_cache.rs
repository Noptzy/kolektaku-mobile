use std::path::PathBuf;
use std::sync::Arc;

use application::ports::Clock;

const EXTENSION: &str = "cache";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CacheHit {
    pub body: String,
    pub age_secs: u64,
}

pub struct ResponseCache {
    folder: PathBuf,
    clock: Arc<dyn Clock>,
    capacity: usize,
}

fn fingerprint(key: &str) -> u64 {
    key.bytes().fold(0xcbf2_9ce4_8422_2325, |hash, byte| {
        (hash ^ u64::from(byte)).wrapping_mul(0x0000_0100_0000_01b3)
    })
}

impl ResponseCache {
    pub fn new(folder: impl Into<PathBuf>, clock: Arc<dyn Clock>, capacity: usize) -> Self {
        Self {
            folder: folder.into(),
            clock,
            capacity,
        }
    }

    fn file_of(&self, key: &str) -> PathBuf {
        self.folder
            .join(format!("{:016x}.{EXTENSION}", fingerprint(key)))
    }

    pub async fn lookup(&self, key: &str) -> Option<CacheHit> {
        let text = tokio::fs::read_to_string(self.file_of(key)).await.ok()?;
        let (stamp, body) = text.split_once('\n')?;
        let saved: u64 = stamp.parse().ok()?;
        Some(CacheHit {
            body: body.to_string(),
            age_secs: self.clock.now_secs().saturating_sub(saved),
        })
    }

    pub async fn store(&self, key: &str, body: &str) {
        if tokio::fs::create_dir_all(&self.folder).await.is_err() {
            return;
        }
        let text = format!("{}\n{body}", self.clock.now_secs());
        let target = self.file_of(key);
        let temporary = target.with_extension("tmp");
        if tokio::fs::write(&temporary, text).await.is_ok() {
            let _ = tokio::fs::rename(&temporary, &target).await;
        }
    }

    pub async fn clear(&self) {
        for file in self.files().await {
            let _ = tokio::fs::remove_file(file.0).await;
        }
    }

    pub async fn prune(&self) {
        let mut files = self.files().await;
        if files.len() <= self.capacity {
            return;
        }
        files.sort_by_key(|file| file.1);
        let surplus = files.len() - self.capacity;
        for file in files.into_iter().take(surplus) {
            let _ = tokio::fs::remove_file(file.0).await;
        }
    }

    async fn files(&self) -> Vec<(PathBuf, std::time::SystemTime)> {
        let Ok(mut entries) = tokio::fs::read_dir(&self.folder).await else {
            return Vec::new();
        };
        let mut found = Vec::new();
        while let Ok(Some(entry)) = entries.next_entry().await {
            let path = entry.path();
            if path.extension().and_then(|text| text.to_str()) != Some(EXTENSION) {
                continue;
            }
            let modified = entry
                .metadata()
                .await
                .and_then(|meta| meta.modified())
                .unwrap_or(std::time::UNIX_EPOCH);
            found.push((path, modified));
        }
        found
    }
}

#[cfg(test)]
mod tests {
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
}
