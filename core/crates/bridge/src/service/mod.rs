pub mod browse;
pub mod detail;
pub mod downloads;
pub mod follow;
pub mod highlights;
pub mod library;
pub mod people;
pub mod play;
pub mod scene;
pub mod settings;
pub mod sources;
pub mod subtitle;
pub mod translate;
pub mod update;

#[cfg(test)]
mod cache_tests;
#[cfg(test)]
mod downloads_tests;
#[cfg(test)]
mod follow_tests;
#[cfg(test)]
mod highlights_tests;
#[cfg(test)]
mod people_search_tests;
#[cfg(test)]
mod scene_tests;
#[cfg(test)]
mod service_library_tests;
#[cfg(test)]
mod service_novel_chapter_tests;
#[cfg(test)]
mod service_novel_tests;
#[cfg(test)]
mod service_support;
#[cfg(test)]
mod service_tests;
#[cfg(test)]
mod settings_tests;
#[cfg(test)]
mod sources_ping_tests;
#[cfg(test)]
mod subtitle_tests;
#[cfg(test)]
mod subtitle_translation_tests;
#[cfg(test)]
mod translate_tests;
#[cfg(test)]
mod update_check_tests;
#[cfg(test)]
mod update_download_tests;
#[cfg(test)]
mod update_support;
