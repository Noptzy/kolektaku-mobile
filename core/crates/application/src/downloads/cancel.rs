use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};

#[derive(Debug, Clone, Default)]
pub struct CancelToken {
    cancelled: Arc<AtomicBool>,
}

impl CancelToken {
    pub fn cancel(&self) {
        self.cancelled.store(true, Ordering::SeqCst);
    }

    pub fn is_cancelled(&self) -> bool {
        self.cancelled.load(Ordering::SeqCst)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_copy_sees_the_cancellation() {
        let token = CancelToken::default();
        let copy = token.clone();
        assert!(!copy.is_cancelled());
        token.cancel();
        assert!(copy.is_cancelled());
    }
}
