use std::path::PathBuf;

use application::ports::BoxFuture;

pub trait ConfigStore: Send + Sync {
    fn read(&self) -> BoxFuture<'_, Option<String>>;

    fn write(&self, text: String) -> BoxFuture<'_, ()>;
}

pub struct FileConfigStore {
    path: PathBuf,
}

impl FileConfigStore {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
    }

    fn temporary_path(&self) -> PathBuf {
        let mut name = self.path.file_name().unwrap_or_default().to_os_string();
        name.push(".tmp");
        self.path.with_file_name(name)
    }
}

impl ConfigStore for FileConfigStore {
    fn read(&self) -> BoxFuture<'_, Option<String>> {
        Box::pin(async move { tokio::fs::read_to_string(&self.path).await.ok() })
    }

    fn write(&self, text: String) -> BoxFuture<'_, ()> {
        Box::pin(async move {
            let temporary = self.temporary_path();
            if let Some(folder) = self.path.parent() {
                let _ = tokio::fs::create_dir_all(folder).await;
            }
            if tokio::fs::write(&temporary, text).await.is_ok() {
                let _ = tokio::fs::rename(&temporary, &self.path).await;
            }
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn temporary_folder(name: &str) -> PathBuf {
        let folder =
            std::env::temp_dir().join(format!("kolektaku-config-{name}-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&folder);
        folder
    }

    #[tokio::test]
    async fn a_missing_file_reads_as_nothing() {
        let store = FileConfigStore::new(temporary_folder("missing").join("config.json"));
        assert_eq!(store.read().await, None);
    }

    #[tokio::test]
    async fn written_text_is_read_back_and_replaced_atomically() {
        let folder = temporary_folder("roundtrip");
        let store = FileConfigStore::new(folder.join("nested").join("config.json"));
        store.write("first".into()).await;
        assert_eq!(store.read().await.as_deref(), Some("first"));
        store.write("second".into()).await;
        assert_eq!(store.read().await.as_deref(), Some("second"));
        assert!(!folder.join("nested").join("config.json.tmp").exists());
        let _ = std::fs::remove_dir_all(&folder);
    }
}
