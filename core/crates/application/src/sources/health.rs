use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use domain::error::SourceError;
use domain::source::SourceId;

use super::misses::SearchMisses;
use crate::ports::Clock;

const FAILURES_BEFORE_SKIPPING: u32 = 3;
const SKIP_SECS: u64 = 600;

#[derive(Default)]
struct Record {
    streak: u32,
    skip_until: u64,
}

pub struct SourceHealth {
    clock: Arc<dyn Clock>,
    records: Mutex<HashMap<SourceId, Record>>,
    misses: SearchMisses,
}

impl SourceHealth {
    pub fn new(clock: Arc<dyn Clock>) -> Self {
        Self {
            clock,
            records: Mutex::new(HashMap::new()),
            misses: SearchMisses::default(),
        }
    }

    pub fn misses(&self) -> &SearchMisses {
        &self.misses
    }

    pub fn record_success(&self, source: &SourceId) {
        self.records.lock().unwrap().remove(source);
    }

    pub fn record_failure(&self, source: &SourceId, error: &SourceError) {
        if !error.counts_against_source_health() {
            return;
        }
        let now = self.clock.now_secs();
        let mut records = self.records.lock().unwrap();
        let record = records.entry(source.clone()).or_default();
        record.streak += 1;
        if record.streak >= FAILURES_BEFORE_SKIPPING {
            record.skip_until = now + SKIP_SECS;
            record.streak = 0;
        }
    }

    pub fn is_skipped(&self, source: &SourceId) -> bool {
        let now = self.clock.now_secs();
        self.records
            .lock()
            .unwrap()
            .get(source)
            .is_some_and(|record| record.skip_until > now)
    }

    pub fn recent_failures(&self, source: &SourceId) -> u32 {
        self.records
            .lock()
            .unwrap()
            .get(source)
            .map_or(0, |record| record.streak)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::FakeClock;

    fn health() -> (SourceHealth, Arc<FakeClock>) {
        let clock = Arc::new(FakeClock::at(1_000));
        (SourceHealth::new(clock.clone()), clock)
    }

    fn down() -> SourceError {
        SourceError::Unavailable("down".into())
    }

    #[test]
    fn three_failures_in_a_row_skip_the_site_for_ten_minutes() {
        let (health, clock) = health();
        let site = SourceId::new("a");
        health.record_failure(&site, &down());
        health.record_failure(&site, &down());
        assert!(!health.is_skipped(&site));
        health.record_failure(&site, &down());
        assert!(health.is_skipped(&site));
        clock.advance(599);
        assert!(health.is_skipped(&site));
        clock.advance(1);
        assert!(!health.is_skipped(&site));
    }

    #[test]
    fn a_success_resets_the_streak() {
        let (health, _) = health();
        let site = SourceId::new("a");
        health.record_failure(&site, &down());
        health.record_failure(&site, &down());
        health.record_success(&site);
        health.record_failure(&site, &down());
        assert!(!health.is_skipped(&site));
        assert_eq!(health.recent_failures(&site), 1);
    }

    #[test]
    fn errors_that_are_not_the_sites_fault_do_not_count() {
        let (health, _) = health();
        let site = SourceId::new("a");
        for _ in 0..5 {
            health.record_failure(&site, &SourceError::NotFound("x".into()));
        }
        assert!(!health.is_skipped(&site));
        assert_eq!(health.recent_failures(&site), 0);
    }

    #[test]
    fn sites_are_tracked_independently() {
        let (health, _) = health();
        let (a, b) = (SourceId::new("a"), SourceId::new("b"));
        for _ in 0..3 {
            health.record_failure(&a, &down());
        }
        assert!(health.is_skipped(&a));
        assert!(!health.is_skipped(&b));
    }

    #[test]
    fn a_skipped_site_that_recovers_starts_fresh() {
        let (health, clock) = health();
        let site = SourceId::new("a");
        for _ in 0..3 {
            health.record_failure(&site, &down());
        }
        clock.advance(601);
        health.record_failure(&site, &down());
        assert!(!health.is_skipped(&site));
        assert_eq!(health.recent_failures(&site), 1);
    }
}
