use std::path::PathBuf;
use std::sync::Arc;

use application::ports::Clock;

use crate::storage::{CacheStore, Database};

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
    database: Option<CacheStore>,
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
            database: None,
        }
    }

    pub fn in_database(
        database: Database,
        group: &str,
        clock: Arc<dyn Clock>,
        capacity: usize,
    ) -> Self {
        Self {
            folder: PathBuf::new(),
            clock: clock.clone(),
            capacity,
            database: Some(CacheStore::new(database, group, clock, capacity)),
        }
    }

    fn file_of(&self, key: &str) -> PathBuf {
        self.folder
            .join(format!("{:016x}.{EXTENSION}", fingerprint(key)))
    }

    pub async fn lookup(&self, key: &str) -> Option<CacheHit> {
        if let Some(store) = &self.database {
            let (body, age_secs) = store.lookup(key).await?;
            return Some(CacheHit { body, age_secs });
        }
        let text = tokio::fs::read_to_string(self.file_of(key)).await.ok()?;
        let (stamp, body) = text.split_once('\n')?;
        let saved: u64 = stamp.parse().ok()?;
        Some(CacheHit {
            body: body.to_string(),
            age_secs: self.clock.now_secs().saturating_sub(saved),
        })
    }

    pub async fn store(&self, key: &str, body: &str) {
        if let Some(store) = &self.database {
            return store.store(key, body).await;
        }
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
        if let Some(store) = &self.database {
            return store.clear().await;
        }
        for file in self.files().await {
            let _ = tokio::fs::remove_file(file.0).await;
        }
    }

    pub async fn prune(&self) {
        if let Some(store) = &self.database {
            return store.prune().await;
        }
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
mod tests;
