pub trait TranslationHealth: Send + Sync {
    fn paused_until(&self) -> Option<u64>;
}
