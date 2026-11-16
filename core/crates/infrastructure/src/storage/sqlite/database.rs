use std::fmt::Display;
use std::path::Path;
use std::sync::{Arc, Mutex};

use domain::error::StorageError;
use rusqlite::Connection;

use super::migrate::migrate;

#[derive(Clone)]
pub struct Database {
    connection: Arc<Mutex<Connection>>,
}

pub fn failure(error: impl Display) -> StorageError {
    StorageError(format!("sqlite: {error}"))
}

fn prepared(mut connection: Connection) -> Result<Database, StorageError> {
    let _mode: Result<String, _> =
        connection.query_row("PRAGMA journal_mode=WAL", [], |row| row.get(0));
    connection
        .pragma_update(None, "foreign_keys", "ON")
        .map_err(failure)?;
    migrate(&mut connection).map_err(failure)?;
    Ok(Database {
        connection: Arc::new(Mutex::new(connection)),
    })
}

impl Database {
    pub fn open(path: &Path) -> Result<Self, StorageError> {
        if let Some(folder) = path.parent() {
            std::fs::create_dir_all(folder).map_err(failure)?;
        }
        prepared(Connection::open(path).map_err(failure)?)
    }

    pub fn in_memory() -> Result<Self, StorageError> {
        prepared(Connection::open_in_memory().map_err(failure)?)
    }

    pub async fn run<R: Send + 'static>(
        &self,
        work: impl FnOnce(&mut Connection) -> rusqlite::Result<R> + Send + 'static,
    ) -> Result<R, StorageError> {
        let connection = Arc::clone(&self.connection);
        tokio::task::spawn_blocking(move || {
            let mut guard = connection
                .lock()
                .map_err(|_| failure("database lock was poisoned"))?;
            work(&mut guard).map_err(failure)
        })
        .await
        .map_err(failure)?
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::storage::TempFolder;

    #[tokio::test]
    async fn a_new_database_is_created_with_the_latest_schema() {
        let folder = TempFolder::new("db-create");
        let database = Database::open(&folder.file("deep/kolektaku.db")).unwrap();
        let version: i64 = database
            .run(|conn| conn.query_row("PRAGMA user_version", [], |row| row.get(0)))
            .await
            .unwrap();
        assert_eq!(version, super::super::migrate::latest_version() as i64);
    }

    #[tokio::test]
    async fn data_written_in_one_session_is_there_in_the_next() {
        let folder = TempFolder::new("db-restart");
        let path = folder.file("kolektaku.db");
        {
            let database = Database::open(&path).unwrap();
            database
                .run(|conn| {
                    conn.execute("INSERT INTO preference(name, value) VALUES ('a', 'b')", [])
                })
                .await
                .unwrap();
        }
        let database = Database::open(&path).unwrap();
        let value: String = database
            .run(|conn| {
                conn.query_row("SELECT value FROM preference WHERE name='a'", [], |row| {
                    row.get(0)
                })
            })
            .await
            .unwrap();
        assert_eq!(value, "b");
    }

    #[tokio::test]
    async fn a_failing_statement_is_reported_not_swallowed() {
        let database = Database::in_memory().unwrap();
        let result = database
            .run(|conn| conn.execute("INSERT INTO no_such_table VALUES (1)", []))
            .await;
        assert!(result.is_err());
    }
}
