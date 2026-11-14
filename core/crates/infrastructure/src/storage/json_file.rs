use std::path::PathBuf;

use domain::error::StorageError;
use serde::Serialize;
use serde::de::DeserializeOwned;
use tokio::sync::Mutex;

pub struct JsonFile {
    path: PathBuf,
    gate: Mutex<()>,
}

fn failure(action: &str, error: impl std::fmt::Display) -> StorageError {
    StorageError(format!("{action}: {error}"))
}

impl JsonFile {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self {
            path: path.into(),
            gate: Mutex::new(()),
        }
    }

    pub async fn read<T: DeserializeOwned + Default>(&self) -> T {
        let _turn = self.gate.lock().await;
        self.load().await
    }

    pub async fn update<T, R>(&self, change: impl FnOnce(&mut T) -> R) -> Result<R, StorageError>
    where
        T: DeserializeOwned + Serialize + Default,
    {
        let _turn = self.gate.lock().await;
        let mut document: T = self.load().await;
        let result = change(&mut document);
        self.store(&document).await?;
        Ok(result)
    }

    async fn load<T: DeserializeOwned + Default>(&self) -> T {
        let Ok(text) = tokio::fs::read_to_string(&self.path).await else {
            return T::default();
        };
        match serde_json::from_str(&text) {
            Ok(document) => document,
            Err(_) => {
                self.set_corrupt_file_aside().await;
                T::default()
            }
        }
    }

    async fn set_corrupt_file_aside(&self) {
        let mut name = self.path.file_name().unwrap_or_default().to_os_string();
        name.push(".corrupt");
        let _ = tokio::fs::rename(&self.path, self.path.with_file_name(name)).await;
    }

    async fn store<T: Serialize>(&self, document: &T) -> Result<(), StorageError> {
        let text = serde_json::to_string(document).map_err(|error| failure("encode", error))?;
        if let Some(folder) = self.path.parent() {
            tokio::fs::create_dir_all(folder)
                .await
                .map_err(|error| failure("create folder", error))?;
        }
        let mut name = self.path.file_name().unwrap_or_default().to_os_string();
        name.push(".tmp");
        let temporary = self.path.with_file_name(name);
        tokio::fs::write(&temporary, text)
            .await
            .map_err(|error| failure("write", error))?;
        tokio::fs::rename(&temporary, &self.path)
            .await
            .map_err(|error| failure("replace", error))
    }
}
