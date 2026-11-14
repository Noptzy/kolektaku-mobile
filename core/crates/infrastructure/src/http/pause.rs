use std::time::{Duration, SystemTime, UNIX_EPOCH};

use application::ports::BoxFuture;

pub trait Pause: Send + Sync {
    fn now_millis(&self) -> u64;
    fn sleep(&self, millis: u64) -> BoxFuture<'_, ()>;
}

pub struct SystemPause;

impl Pause for SystemPause {
    fn now_millis(&self) -> u64 {
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_or(0, |elapsed| elapsed.as_millis() as u64)
    }

    fn sleep(&self, millis: u64) -> BoxFuture<'_, ()> {
        Box::pin(tokio::time::sleep(Duration::from_millis(millis)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn sleeping_moves_the_clock_forward() {
        let pause = SystemPause;
        let before = pause.now_millis();
        pause.sleep(20).await;
        assert!(pause.now_millis() >= before + 15);
    }

    #[test]
    fn the_clock_reads_a_plausible_date() {
        assert!(SystemPause.now_millis() > 1_700_000_000_000);
    }
}
