use std::collections::HashMap;
use std::sync::{Arc, RwLock};

use domain::error::StorageError;
use domain::library::LibraryRepository;
use domain::settings::{AppSettings, SETTING_KEYS};
use domain::source::SourceId;

pub struct AppSettingsStore {
    current: RwLock<AppSettings>,
}

impl AppSettingsStore {
    pub fn holding(settings: AppSettings) -> Arc<Self> {
        Arc::new(Self {
            current: RwLock::new(settings),
        })
    }

    pub async fn load<L: LibraryRepository>(library: &L) -> Arc<Self> {
        let mut stored: HashMap<&str, String> = HashMap::new();
        for key in SETTING_KEYS {
            if let Ok(Some(value)) = library.preference(key).await {
                stored.insert(key, value);
            }
        }
        Self::holding(AppSettings::from_lookup(|key| stored.get(key).cloned()))
    }

    pub fn get(&self) -> AppSettings {
        self.current.read().unwrap().clone()
    }

    pub fn preferred_anime_source(&self) -> Option<SourceId> {
        self.current.read().unwrap().anime_source.clone()
    }

    pub async fn save<L: LibraryRepository>(
        &self,
        library: &L,
        settings: AppSettings,
    ) -> Result<(), StorageError> {
        *self.current.write().unwrap() = settings.clone();
        for (key, value) in settings.entries() {
            library.set_preference(key, &value).await?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use domain::settings::{QualityPreference, SubtitleLanguage};

    use super::*;
    use crate::testing::MemoryLibrary;

    fn changed() -> AppSettings {
        AppSettings {
            prefers_anime: false,
            anime_source: Some(SourceId::new("second")),
            subtitle_language: SubtitleLanguage::English,
            quality: QualityPreference::P480,
            auto_skip: true,
            ..AppSettings::default()
        }
    }

    #[tokio::test]
    async fn a_fresh_library_gives_the_defaults() {
        let store = AppSettingsStore::load(&MemoryLibrary::new()).await;
        assert_eq!(store.get(), AppSettings::default());
        assert_eq!(store.preferred_anime_source(), None);
    }

    #[tokio::test]
    async fn saved_settings_are_visible_at_once_and_after_a_reload() {
        let library = MemoryLibrary::new();
        let store = AppSettingsStore::load(&library).await;
        store.save(&library, changed()).await.unwrap();
        assert_eq!(store.get(), changed());
        assert_eq!(
            store.preferred_anime_source(),
            Some(SourceId::new("second"))
        );
        let reloaded = AppSettingsStore::load(&library).await;
        assert_eq!(reloaded.get(), changed());
    }

    #[tokio::test]
    async fn clearing_the_preferred_source_is_remembered() {
        let library = MemoryLibrary::new();
        let store = AppSettingsStore::load(&library).await;
        store.save(&library, changed()).await.unwrap();
        store.save(&library, AppSettings::default()).await.unwrap();
        let reloaded = AppSettingsStore::load(&library).await;
        assert_eq!(reloaded.preferred_anime_source(), None);
    }
}
