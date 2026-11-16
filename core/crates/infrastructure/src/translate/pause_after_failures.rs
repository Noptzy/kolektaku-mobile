use std::sync::Mutex;

pub const FAILURES_BEFORE_PAUSE: u32 = 3;
pub const PAUSE_SECS: u64 = 10 * 60;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ServiceState {
    Normal,
    PausedUntil(u64),
}

#[derive(Default)]
struct Tally {
    failures_in_a_row: u32,
    paused_until: Option<u64>,
}

#[derive(Default)]
pub struct PauseAfterFailures {
    tally: Mutex<Tally>,
}

impl PauseAfterFailures {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn state_at(&self, now: u64) -> ServiceState {
        let mut tally = self.tally.lock().unwrap();
        match tally.paused_until {
            Some(until) if now < until => ServiceState::PausedUntil(until),
            Some(_) => {
                *tally = Tally::default();
                ServiceState::Normal
            }
            None => ServiceState::Normal,
        }
    }

    pub fn record_failure(&self, now: u64) {
        let mut tally = self.tally.lock().unwrap();
        tally.failures_in_a_row += 1;
        if tally.failures_in_a_row >= FAILURES_BEFORE_PAUSE {
            tally.paused_until = Some(now + PAUSE_SECS);
        }
    }

    pub fn record_success(&self) {
        *self.tally.lock().unwrap() = Tally::default();
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_fresh_service_is_normal() {
        assert_eq!(
            PauseAfterFailures::new().state_at(100),
            ServiceState::Normal
        );
    }

    #[test]
    fn two_failures_do_not_pause() {
        let pause = PauseAfterFailures::new();
        pause.record_failure(100);
        pause.record_failure(101);
        assert_eq!(pause.state_at(102), ServiceState::Normal);
    }

    #[test]
    fn the_third_failure_in_a_row_pauses_for_ten_minutes() {
        let pause = PauseAfterFailures::new();
        for second in 0..3 {
            pause.record_failure(100 + second);
        }
        assert_eq!(pause.state_at(103), ServiceState::PausedUntil(102 + 600));
        assert_eq!(pause.state_at(701), ServiceState::PausedUntil(702));
    }

    #[test]
    fn the_pause_ends_on_time_and_the_count_starts_over() {
        let pause = PauseAfterFailures::new();
        for _ in 0..3 {
            pause.record_failure(0);
        }
        assert_eq!(pause.state_at(PAUSE_SECS), ServiceState::Normal);
        pause.record_failure(PAUSE_SECS + 1);
        assert_eq!(pause.state_at(PAUSE_SECS + 2), ServiceState::Normal);
    }

    #[test]
    fn a_success_clears_the_streak() {
        let pause = PauseAfterFailures::new();
        pause.record_failure(1);
        pause.record_failure(2);
        pause.record_success();
        pause.record_failure(3);
        pause.record_failure(4);
        assert_eq!(pause.state_at(5), ServiceState::Normal);
    }
}
