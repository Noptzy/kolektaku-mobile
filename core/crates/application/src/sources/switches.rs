use std::collections::HashSet;
use std::sync::{Arc, RwLock};

use domain::library::LibraryRepository;
use domain::source::SourceId;

const PREFERENCE: &str = "disabled_sources";

#[derive(Default)]
pub struct SourceSwitches {
    disabled: RwLock<HashSet<SourceId>>,
}

impl SourceSwitches {
    pub async fn load<L: LibraryRepository>(library: &L) -> Arc<Self> {
        let stored = library
            .preference(PREFERENCE)
            .await
            .ok()
            .flatten()
            .unwrap_or_default();
        let disabled = stored
            .split(',')
            .filter(|id| !id.trim().is_empty())
            .map(|id| SourceId::new(id.trim()))
            .collect();
        Arc::new(Self {
            disabled: RwLock::new(disabled),
        })
    }

    pub fn is_enabled(&self, id: &SourceId) -> bool {
        !self.disabled.read().unwrap().contains(id)
    }

    pub async fn set_enabled<L: LibraryRepository>(
        &self,
        library: &L,
        id: &SourceId,
        enabled: bool,
    ) {
        let serialized = {
            let mut disabled = self.disabled.write().unwrap();
            if enabled {
                disabled.remove(id);
            } else {
                disabled.insert(id.clone());
            }
            let mut names: Vec<&str> = disabled.iter().map(SourceId::as_str).collect();
            names.sort_unstable();
            names.join(",")
        };
        let _ = library.set_preference(PREFERENCE, &serialized).await;
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::MemoryLibrary;

    #[tokio::test]
    async fn everything_is_enabled_until_switched_off_and_the_choice_is_remembered() {
        let library = MemoryLibrary::new();
        let switches = SourceSwitches::load(&library).await;
        let site = SourceId::new("komiku");
        assert!(switches.is_enabled(&site));
        switches.set_enabled(&library, &site, false).await;
        assert!(!switches.is_enabled(&site));
        let again = SourceSwitches::load(&library).await;
        assert!(!again.is_enabled(&site));
        again.set_enabled(&library, &site, true).await;
        assert!(SourceSwitches::load(&library).await.is_enabled(&site));
    }

    #[tokio::test]
    async fn several_disabled_sites_are_stored_together() {
        let library = MemoryLibrary::new();
        let switches = SourceSwitches::load(&library).await;
        switches
            .set_enabled(&library, &SourceId::new("b"), false)
            .await;
        switches
            .set_enabled(&library, &SourceId::new("a"), false)
            .await;
        assert_eq!(
            library.preference(PREFERENCE).await.unwrap().as_deref(),
            Some("a,b")
        );
    }
}
