use std::path::{Path, PathBuf};

use domain::error::StorageError;
use rusqlite::{Connection, Transaction, params};

use super::database::Database;
use super::links::put_links;
use super::rows::{encode, media_key};
use crate::storage::library::LibraryDocument;
use crate::storage::source_links::LinkDocument;

const LIBRARY_FILE: &str = "library.json";
const LINKS_FILE: &str = "source_links.json";
const MIGRATED_SUFFIX: &str = "migrated";

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct ImportReport {
    pub favorites: usize,
    pub history: usize,
    pub unit_orders: usize,
    pub searches: usize,
    pub preferences: usize,
    pub links: usize,
}

fn migrated_name(path: &Path) -> PathBuf {
    let mut name = path.file_name().unwrap_or_default().to_os_string();
    name.push(format!(".{MIGRATED_SUFFIX}"));
    path.with_file_name(name)
}

fn read_json<T: serde::de::DeserializeOwned>(path: &Path) -> Option<T> {
    let text = std::fs::read_to_string(path).ok()?;
    serde_json::from_str(&text).ok()
}

fn library_rows(
    transaction: &Transaction,
    document: &LibraryDocument,
) -> rusqlite::Result<ImportReport> {
    let mut report = ImportReport::default();
    for favorite in &document.favorites {
        transaction.execute(
            "INSERT OR REPLACE INTO favorite(kind, media_key, added_at, data) \
             VALUES (?1, ?2, ?3, ?4)",
            params![
                favorite.entry.kind.as_str(),
                media_key(&favorite.entry.media)?,
                favorite.added_at_secs as i64,
                encode(favorite)?
            ],
        )?;
        report.favorites += 1;
    }
    for progress in &document.history {
        transaction.execute(
            "DELETE FROM progress WHERE kind = ?1 AND media_key = ?2 AND ABS(unit - ?3) < 1e-9",
            params![
                progress.entry.kind.as_str(),
                media_key(&progress.entry.media)?,
                progress.entry.unit_number
            ],
        )?;
        transaction.execute(
            "INSERT INTO progress(kind, media_key, unit, updated_at, data) \
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![
                progress.entry.kind.as_str(),
                media_key(&progress.entry.media)?,
                progress.entry.unit_number,
                progress.entry.updated_at_secs as i64,
                encode(progress)?
            ],
        )?;
        report.history += 1;
    }
    for entry in &document.unit_orders {
        transaction.execute(
            "INSERT OR REPLACE INTO unit_order(kind, media_key, data) VALUES (?1, ?2, ?3)",
            params![
                entry.kind.as_str(),
                media_key(&entry.media)?,
                encode(&entry.order)?
            ],
        )?;
        report.unit_orders += 1;
    }
    for (name, value) in &document.preferences {
        transaction.execute(
            "INSERT OR REPLACE INTO preference(name, value) VALUES (?1, ?2)",
            [name, value],
        )?;
        report.preferences += 1;
    }
    for (kind, queries) in &document.searches {
        transaction.execute("DELETE FROM search_history WHERE kind = ?1", [kind])?;
        for (position, query) in queries.iter().enumerate() {
            transaction.execute(
                "INSERT INTO search_history(kind, position, query) VALUES (?1, ?2, ?3)",
                params![kind, position as i64, query],
            )?;
            report.searches += 1;
        }
    }
    Ok(report)
}

fn bring_in(
    connection: &mut Connection,
    library: Option<LibraryDocument>,
    links: Option<LinkDocument>,
) -> rusqlite::Result<ImportReport> {
    let transaction = connection.transaction()?;
    let mut report = match &library {
        Some(document) => library_rows(&transaction, document)?,
        None => ImportReport::default(),
    };
    for entry in links.iter().flat_map(LinkDocument::typed) {
        put_links(&transaction, &entry.media, &entry.links)?;
        report.links += entry.links.len();
    }
    transaction.commit()?;
    Ok(report)
}

pub fn import_sync(
    connection: &mut Connection,
    folder: &Path,
) -> rusqlite::Result<Option<ImportReport>> {
    let (library_path, links_path) = (folder.join(LIBRARY_FILE), folder.join(LINKS_FILE));
    let library = read_json::<LibraryDocument>(&library_path);
    let links = read_json::<LinkDocument>(&links_path);
    if library.is_none() && links.is_none() {
        return Ok(None);
    }
    let (had_library, had_links) = (library.is_some(), links.is_some());
    let report = bring_in(connection, library, links)?;
    if had_library {
        let _ = std::fs::rename(&library_path, migrated_name(&library_path));
    }
    if had_links {
        let _ = std::fs::rename(&links_path, migrated_name(&links_path));
    }
    Ok(Some(report))
}

pub async fn import_legacy(
    database: &Database,
    folder: &Path,
) -> Result<Option<ImportReport>, StorageError> {
    let folder = folder.to_path_buf();
    database
        .run(move |connection| import_sync(connection, &folder))
        .await
}
