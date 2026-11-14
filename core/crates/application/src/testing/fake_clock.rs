use std::sync::atomic::{AtomicU64, Ordering};

use crate::ports::Clock;

pub struct FakeClock(AtomicU64);

impl FakeClock {
    pub fn at(secs: u64) -> Self {
        Self(AtomicU64::new(secs))
    }

    pub fn advance(&self, secs: u64) {
        self.0.fetch_add(secs, Ordering::SeqCst);
    }
}

impl Clock for FakeClock {
    fn now_secs(&self) -> u64 {
        self.0.load(Ordering::SeqCst)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn starts_at_the_given_time_and_advances_on_demand() {
        let clock = FakeClock::at(100);
        assert_eq!(clock.now_secs(), 100);
        clock.advance(30);
        assert_eq!(clock.now_secs(), 130);
    }
}
