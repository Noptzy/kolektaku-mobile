use domain::library::UnitOrder;
use domain::media::{MediaKind, MediaRef};
use rusqlite::{Connection, OptionalExtension, params};

use super::rows::{encode, media_key};

const MAX_SEARCHES: usize = 8;

pub fn unit_order(
    connection: &Connection,
    kind: MediaKind,
    media: &MediaRef,
) -> rusqlite::Result<UnitOrder> {
    let text: Option<String> = connection
        .query_row(
            "SELECT data FROM unit_order WHERE kind = ?1 AND media_key = ?2",
            params![kind.as_str(), media_key(media)?],
            |row| row.get(0),
        )
        .optional()?;
    Ok(text
        .and_then(|text| serde_json::from_str(&text).ok())
        .unwrap_or_default())
}

pub fn set_unit_order(
    connection: &Connection,
    kind: MediaKind,
    media: &MediaRef,
    order: UnitOrder,
) -> rusqlite::Result<()> {
    let key = media_key(media)?;
    if order == UnitOrder::default() {
        connection.execute(
            "DELETE FROM unit_order WHERE kind = ?1 AND media_key = ?2",
            params![kind.as_str(), key],
        )?;
        return Ok(());
    }
    connection.execute(
        "INSERT OR REPLACE INTO unit_order(kind, media_key, data) VALUES (?1, ?2, ?3)",
        params![kind.as_str(), key, encode(&order)?],
    )?;
    Ok(())
}

pub fn preference(connection: &Connection, name: &str) -> rusqlite::Result<Option<String>> {
    connection
        .query_row(
            "SELECT value FROM preference WHERE name = ?1",
            [name],
            |row| row.get(0),
        )
        .optional()
}

pub fn set_preference(connection: &Connection, name: &str, value: &str) -> rusqlite::Result<()> {
    connection.execute(
        "INSERT OR REPLACE INTO preference(name, value) VALUES (?1, ?2)",
        [name, value],
    )?;
    Ok(())
}

pub fn searches(connection: &Connection, kind: MediaKind) -> rusqlite::Result<Vec<String>> {
    let mut statement = connection
        .prepare("SELECT query FROM search_history WHERE kind = ?1 ORDER BY position ASC")?;
    let rows = statement.query_map([kind.as_str()], |row| row.get::<_, String>(0))?;
    rows.collect()
}

pub fn add_search(
    connection: &mut Connection,
    kind: MediaKind,
    query: &str,
) -> rusqlite::Result<()> {
    let query = query.trim();
    if query.is_empty() {
        return Ok(());
    }
    let wanted = query.to_lowercase();
    let mut recent: Vec<String> = searches(connection, kind)?
        .into_iter()
        .filter(|known| known.to_lowercase() != wanted)
        .collect();
    recent.insert(0, query.to_string());
    recent.truncate(MAX_SEARCHES);
    let transaction = connection.transaction()?;
    transaction.execute(
        "DELETE FROM search_history WHERE kind = ?1",
        [kind.as_str()],
    )?;
    for (position, text) in recent.iter().enumerate() {
        transaction.execute(
            "INSERT INTO search_history(kind, position, query) VALUES (?1, ?2, ?3)",
            params![kind.as_str(), position as i64, text],
        )?;
    }
    transaction.commit()
}

pub fn clear_searches(connection: &Connection, kind: MediaKind) -> rusqlite::Result<()> {
    connection.execute(
        "DELETE FROM search_history WHERE kind = ?1",
        [kind.as_str()],
    )?;
    Ok(())
}
