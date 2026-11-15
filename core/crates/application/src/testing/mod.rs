mod call_recorder;
mod fake_catalog;
mod fake_catalog_builders;
#[cfg(test)]
mod fake_catalog_tests;
mod fake_clock;
mod fake_genres;
mod fake_pages;
mod fake_scene_search;
mod fake_source;
mod fake_source_builder;
#[cfg(test)]
mod fake_source_tests;
mod fake_text;
mod fake_translator;
mod fake_video;
mod memory_library;
#[cfg(test)]
mod memory_library_tests;
mod memory_link_store;
mod memory_state;

use call_recorder::CallRecorder;

pub use fake_catalog::FakeCatalog;
pub use fake_clock::FakeClock;
pub use fake_genres::FakeGenres;
pub use fake_pages::FakePages;
pub use fake_scene_search::FakeSceneSearch;
pub use fake_source::FakeSource;
pub use fake_text::FakeText;
pub use fake_translator::FakeTranslator;
pub use fake_video::FakeVideo;
pub use memory_library::MemoryLibrary;
pub use memory_link_store::MemoryLinkStore;
