use std::collections::HashMap;
use std::sync::Arc;

use domain::error::SourceError;
use domain::source::SourceId;

use crate::ports::{PageSource, SourceProvider, TextSource, VideoSource};
use crate::settings::AppSettingsStore;

#[derive(Clone)]
pub struct SourceDirectory {
    sources: Vec<Arc<dyn SourceProvider>>,
    settings: Option<Arc<AppSettingsStore>>,
}

impl SourceDirectory {
    pub fn new(sources: Vec<Arc<dyn SourceProvider>>) -> Self {
        Self {
            sources,
            settings: None,
        }
    }

    pub fn with_settings(mut self, settings: Arc<AppSettingsStore>) -> Self {
        self.settings = Some(settings);
        self
    }

    pub fn preferred(&self) -> Option<SourceId> {
        self.settings
            .as_ref()
            .and_then(|settings| settings.preferred_anime_source())
    }

    pub fn get(&self, id: &SourceId) -> Result<&Arc<dyn SourceProvider>, SourceError> {
        self.sources
            .iter()
            .find(|source| source.info().id == *id)
            .ok_or_else(|| SourceError::NotFound(format!("source {id}")))
    }

    pub fn video(&self, id: &SourceId) -> Result<&dyn VideoSource, SourceError> {
        self.get(id)?
            .video()
            .ok_or_else(|| SourceError::Unsupported(format!("{id} has no video")))
    }

    pub fn pages(&self, id: &SourceId) -> Result<&dyn PageSource, SourceError> {
        self.get(id)?
            .pages()
            .ok_or_else(|| SourceError::Unsupported(format!("{id} has no pages")))
    }

    pub fn texts(&self, id: &SourceId) -> Result<&dyn TextSource, SourceError> {
        self.get(id)?
            .texts()
            .ok_or_else(|| SourceError::Unsupported(format!("{id} has no text")))
    }

    pub fn priorities(&self) -> HashMap<SourceId, u8> {
        self.sources
            .iter()
            .map(|source| (source.info().id.clone(), source.info().priority))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use domain::media::MediaKind;

    use super::*;
    use crate::testing::{FakeSource, FakeText, FakeVideo};

    fn directory() -> SourceDirectory {
        let plain: Arc<dyn SourceProvider> =
            Arc::new(FakeSource::new("plain", MediaKind::Manga).with_priority(7));
        let streaming: Arc<dyn SourceProvider> =
            Arc::new(FakeSource::new("streaming", MediaKind::Anime).with_video(FakeVideo::new()));
        let reading: Arc<dyn SourceProvider> =
            Arc::new(
                FakeSource::new("reading", MediaKind::Novel)
                    .with_text(FakeText::new().with_chapter("c1", "id", &["Halo"])),
            );
        SourceDirectory::new(vec![plain, streaming, reading])
    }

    #[test]
    fn finds_sources_by_id_and_reports_unknown_ones() {
        let directory = directory();
        assert!(directory.get(&SourceId::new("plain")).is_ok());
        assert!(matches!(
            directory.get(&SourceId::new("ghost")),
            Err(SourceError::NotFound(_))
        ));
    }

    #[test]
    fn video_and_pages_are_only_available_where_declared() {
        let directory = directory();
        assert!(directory.video(&SourceId::new("streaming")).is_ok());
        assert!(matches!(
            directory.video(&SourceId::new("plain")),
            Err(SourceError::Unsupported(_))
        ));
        assert!(matches!(
            directory.pages(&SourceId::new("plain")),
            Err(SourceError::Unsupported(_))
        ));
    }

    #[test]
    fn text_is_only_available_where_declared() {
        let directory = directory();
        assert!(directory.texts(&SourceId::new("reading")).is_ok());
        for id in ["plain", "streaming"] {
            assert!(matches!(
                directory.texts(&SourceId::new(id)),
                Err(SourceError::Unsupported(_))
            ));
        }
        assert!(matches!(
            directory.texts(&SourceId::new("ghost")),
            Err(SourceError::NotFound(_))
        ));
    }

    #[test]
    fn the_preferred_source_comes_from_the_settings_when_attached() {
        use domain::settings::AppSettings;

        assert_eq!(directory().preferred(), None);
        let settings = AppSettingsStore::holding(AppSettings {
            anime_source: Some(SourceId::new("streaming")),
            ..AppSettings::default()
        });
        let attached = directory().with_settings(settings);
        assert_eq!(attached.preferred(), Some(SourceId::new("streaming")));
    }

    #[test]
    fn priorities_are_listed_per_source() {
        let priorities = directory().priorities();
        assert_eq!(priorities[&SourceId::new("plain")], 7);
        assert_eq!(priorities.len(), 3);
    }
}
