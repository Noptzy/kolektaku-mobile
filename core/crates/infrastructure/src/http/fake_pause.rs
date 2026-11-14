use std::sync::Mutex;

use application::ports::BoxFuture;

use super::Pause;

pub struct FakePause {
    now: Mutex<u64>,
    sleeps: Mutex<Vec<u64>>,
}

impl FakePause {
    pub fn at(now_millis: u64) -> Self {
        Self {
            now: Mutex::new(now_millis),
            sleeps: Mutex::new(Vec::new()),
        }
    }

    pub fn sleeps(&self) -> Vec<u64> {
        self.sleeps.lock().unwrap().clone()
    }
}

impl Pause for FakePause {
    fn now_millis(&self) -> u64 {
        *self.now.lock().unwrap()
    }

    fn sleep(&self, millis: u64) -> BoxFuture<'_, ()> {
        Box::pin(async move {
            self.sleeps.lock().unwrap().push(millis);
            *self.now.lock().unwrap() += millis;
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn sleeping_advances_the_clock_and_is_recorded() {
        let pause = FakePause::at(1_000);
        pause.sleep(250).await;
        pause.sleep(750).await;
        assert_eq!(pause.now_millis(), 2_000);
        assert_eq!(pause.sleeps(), vec![250, 750]);
    }
}
