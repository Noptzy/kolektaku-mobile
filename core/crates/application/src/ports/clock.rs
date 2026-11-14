pub trait Clock: Send + Sync {
    fn now_secs(&self) -> u64;
}
