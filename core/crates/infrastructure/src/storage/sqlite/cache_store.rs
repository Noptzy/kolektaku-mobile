use std::sync::Arc;

use application::ports::Clock;
use rusqlite::{OptionalExtension, params};

use super::database::Database;

#[derive(Clone)]
pub struct CacheStore {
    database: Database,
    group: String,
    clock: Arc<dyn Clock>,
    capacity: usize,
}

impl CacheStore {
    pub fn new(database: Database, group: &str, clock: Arc<dyn Clock>, capacity: usize) -> Self {
        Self {
            database,
            group: group.to_string(),
            clock,
            capacity,
        }
    }

    pub async fn lookup(&self, key: &str) -> Option<(String, u64)> {
        let (group, key, now) = (self.group.clone(), key.to_string(), self.clock.now_secs());
        let found = self
            .database
            .run(move |connection| {
                let row: Option<(Vec<u8>, i64)> = connection
                    .query_row(
                        "SELECT body, stored_at FROM cache_entry WHERE grp = ?1 AND key = ?2",
                        params![group, key],
                        |row| Ok((row.get(0)?, row.get(1)?)),
                    )
                    .optional()?;
                if row.is_some() {
                    connection.execute(
                        "UPDATE cache_entry SET used_at = ?3 WHERE grp = ?1 AND key = ?2",
                        params![group, key, now as i64],
                    )?;
                }
                Ok(row)
            })
            .await
            .ok()??;
        let body = String::from_utf8(found.0).ok()?;
        Some((body, now.saturating_sub(found.1.max(0) as u64)))
    }

    pub async fn store(&self, key: &str, body: &str) {
        let (group, key, now) = (self.group.clone(), key.to_string(), self.clock.now_secs());
        let bytes = body.as_bytes().to_vec();
        let _ = self
            .database
            .run(move |connection| {
                connection.execute(
                    "INSERT OR REPLACE INTO cache_entry(grp, key, body, stored_at, used_at, size) \
                     VALUES (?1, ?2, ?3, ?4, ?4, ?5)",
                    params![group, key, bytes, now as i64, bytes.len() as i64],
                )
            })
            .await;
    }

    pub async fn clear(&self) {
        let group = self.group.clone();
        let _ = self
            .database
            .run(move |connection| {
                connection.execute("DELETE FROM cache_entry WHERE grp = ?1", [group])
            })
            .await;
    }

    pub async fn prune(&self) {
        let (group, capacity) = (self.group.clone(), self.capacity as i64);
        let _ = self
            .database
            .run(move |connection| {
                connection.execute(
                    "DELETE FROM cache_entry WHERE grp = ?1 AND key NOT IN \
                     (SELECT key FROM cache_entry WHERE grp = ?1 \
                      ORDER BY used_at DESC, rowid DESC LIMIT ?2)",
                    params![group, capacity],
                )
            })
            .await;
    }
}

#[cfg(test)]
mod tests {
    use application::testing::FakeClock;

    use super::*;

    fn store(
        clock: Arc<FakeClock>,
        group: &str,
        capacity: usize,
        database: &Database,
    ) -> CacheStore {
        CacheStore::new(database.clone(), group, clock, capacity)
    }

    #[tokio::test]
    async fn a_stored_body_comes_back_with_its_age() {
        let clock = Arc::new(FakeClock::at(100));
        let database = Database::in_memory().unwrap();
        let cache = store(clock.clone(), "a", 10, &database);
        cache.store("k", "hello").await;
        clock.advance(30);
        assert_eq!(cache.lookup("k").await, Some(("hello".into(), 30)));
        assert_eq!(cache.lookup("missing").await, None);
    }

    #[tokio::test]
    async fn storing_again_replaces_the_body_and_resets_the_age() {
        let clock = Arc::new(FakeClock::at(100));
        let database = Database::in_memory().unwrap();
        let cache = store(clock.clone(), "a", 10, &database);
        cache.store("k", "old").await;
        clock.advance(50);
        cache.store("k", "new").await;
        assert_eq!(cache.lookup("k").await, Some(("new".into(), 0)));
    }

    #[tokio::test]
    async fn groups_do_not_see_each_other_and_clear_is_per_group() {
        let clock = Arc::new(FakeClock::at(1));
        let database = Database::in_memory().unwrap();
        let one = store(clock.clone(), "one", 10, &database);
        let two = store(clock, "two", 10, &database);
        one.store("k", "1").await;
        two.store("k", "2").await;
        one.clear().await;
        assert_eq!(one.lookup("k").await, None);
        assert_eq!(two.lookup("k").await.unwrap().0, "2");
    }

    #[tokio::test]
    async fn prune_drops_the_least_recently_used_beyond_capacity() {
        let clock = Arc::new(FakeClock::at(1));
        let database = Database::in_memory().unwrap();
        let cache = store(clock.clone(), "a", 2, &database);
        for (index, key) in ["a", "b", "c"].iter().enumerate() {
            clock.advance(10);
            cache.store(key, &index.to_string()).await;
        }
        clock.advance(10);
        assert!(cache.lookup("a").await.is_some());
        cache.prune().await;
        assert!(cache.lookup("b").await.is_none());
        assert!(cache.lookup("a").await.is_some());
        assert!(cache.lookup("c").await.is_some());
    }
}
