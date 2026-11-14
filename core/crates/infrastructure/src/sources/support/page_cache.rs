use std::collections::{HashMap, VecDeque};

const TTL_SECS: u64 = 120;
const CAPACITY: usize = 40;

#[derive(Default)]
pub struct PageCache {
    order: VecDeque<String>,
    entries: HashMap<String, (u64, String)>,
}

impl PageCache {
    pub fn get(&self, url: &str, now_secs: u64) -> Option<String> {
        let (stored_at, body) = self.entries.get(url)?;
        (now_secs.saturating_sub(*stored_at) < TTL_SECS).then(|| body.clone())
    }

    pub fn put(&mut self, url: &str, now_secs: u64, body: String) {
        if self
            .entries
            .insert(url.to_string(), (now_secs, body))
            .is_some()
        {
            self.order.retain(|known| known != url);
        }
        self.order.push_back(url.to_string());
        while self.order.len() > CAPACITY {
            if let Some(oldest) = self.order.pop_front() {
                self.entries.remove(&oldest);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_stored_page_is_returned_until_it_expires() {
        let mut cache = PageCache::default();
        cache.put("a", 100, "body".into());
        assert_eq!(cache.get("a", 100), Some("body".into()));
        assert_eq!(cache.get("a", 219), Some("body".into()));
        assert_eq!(cache.get("a", 220), None);
        assert_eq!(cache.get("missing", 100), None);
    }

    #[test]
    fn the_oldest_page_is_dropped_past_the_capacity() {
        let mut cache = PageCache::default();
        for index in 0..=CAPACITY {
            cache.put(&format!("url{index}"), 0, index.to_string());
        }
        assert_eq!(cache.get("url0", 0), None);
        assert_eq!(cache.get("url1", 0), Some("1".into()));
        assert_eq!(
            cache.get(&format!("url{CAPACITY}"), 0),
            Some(CAPACITY.to_string())
        );
    }

    #[test]
    fn storing_a_page_again_refreshes_it_without_duplicating() {
        let mut cache = PageCache::default();
        cache.put("a", 0, "old".into());
        cache.put("a", 50, "new".into());
        assert_eq!(cache.get("a", 60), Some("new".into()));
        assert_eq!(cache.order.len(), 1);
    }
}
