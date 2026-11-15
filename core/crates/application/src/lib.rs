pub mod catalog;
pub mod detail;
mod greeting;
pub mod library;
pub mod matching;
pub mod ports;
pub mod reading;
pub mod scene;
pub mod settings;
pub mod sources;
pub mod streaming;
#[cfg(any(test, feature = "testing"))]
pub mod testing;
pub mod translation;

pub use greeting::greet;
