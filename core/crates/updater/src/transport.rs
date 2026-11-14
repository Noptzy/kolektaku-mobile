use std::future::Future;
use std::pin::Pin;

use crate::error::UpdateError;

pub type BoxFuture<'a, T> = Pin<Box<dyn Future<Output = T> + Send + 'a>>;

pub trait Body: Send {
    fn next(&mut self) -> BoxFuture<'_, Result<Option<Vec<u8>>, UpdateError>>;
}

pub struct Fetched {
    pub status: u16,
    pub url: String,
    pub body: Box<dyn Body>,
}

pub trait Transport: Send + Sync {
    fn text(&self, url: &str) -> BoxFuture<'_, Result<String, UpdateError>>;

    fn fetch(&self, url: &str, from: u64) -> BoxFuture<'_, Result<Fetched, UpdateError>>;
}
