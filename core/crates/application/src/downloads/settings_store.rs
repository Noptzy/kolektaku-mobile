use std::collections::HashMap;
use std::sync::{Arc, RwLock};

use domain::download::{DOWNLOAD_SETTING_KEYS, DownloadSettings};
use domain::error::StorageError;
use domain::library::LibraryRepository;

pub struct DownloadSettingsStore {
    current: RwLock<DownloadSettings>,
}

impl DownloadSettingsStore {
    pub fn holding(settings: DownloadSettings) -> Arc<Self> {
        Arc::new(Self {
            current: RwLock::new(settings),
        })
    }

    pub async fn load<L: LibraryRepository>(library: &L) -> Arc<Self> {
        let mut stored: HashMap<&str, String> = HashMap::new();
        for key in DOWNLOAD_SETTING_KEYS {
            if let Ok(Some(value)) = library.preference(key).await {
                stored.insert(key, value);
            }
        }
        Self::holding(DownloadSettings::from_lookup(|key| {
            stored.get(key).cloned()
        }))
    }

    pub fn get(&self) -> DownloadSettings {
        *self.current.read().unwrap()
    }

    pub async fn save<L: LibraryRepository>(
        &self,
        library: &L,
        settings: DownloadSettings,
    ) -> Result<(), StorageError> {
        *self.current.write().unwrap() = settings;
        for (key, value) in settings.entries() {
            library.set_preference(key, &value).await?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use domain::download::DownloadSubtitles;
    use domain::settings::QualityPreference;

    use super::*;
    use crate::testing::MemoryLibrary;

    #[tokio::test]
    async fn a_saved_choice_is_read_back_after_a_restart() {
        let library = MemoryLibrary::new();
        let store = DownloadSettingsStore::load(&library).await;
        assert_eq!(store.get(), DownloadSettings::default());
        let chosen = DownloadSettings {
            subtitles: DownloadSubtitles::Original,
            quality: QualityPreference::P480,
        };
        store.save(&library, chosen).await.unwrap();
        assert_eq!(store.get(), chosen);
        assert_eq!(DownloadSettingsStore::load(&library).await.get(), chosen);
    }
}
