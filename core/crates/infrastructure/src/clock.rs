use std::time::{SystemTime, UNIX_EPOCH};

use application::ports::Clock;

pub struct SystemClock;

impl Clock for SystemClock {
    fn now_secs(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_or(0, |elapsed| elapsed.as_secs())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_a_plausible_unix_time() {
        assert!(SystemClock.now_secs() > 1_700_000_000);
    }
}
