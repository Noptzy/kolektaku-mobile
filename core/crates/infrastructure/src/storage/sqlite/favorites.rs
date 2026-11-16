use domain::library::{Favorite, FavoriteInput};
use domain::media::{MediaKind, MediaRef};
use rusqlite::{Connection, params};

use super::rows::{decode_all, encode, media_key};

fn data_of(connection: &Connection, kind: MediaKind) -> rusqlite::Result<Vec<String>> {
    let mut statement = connection
        .prepare("SELECT data FROM favorite WHERE kind = ?1 ORDER BY added_at DESC, rowid DESC")?;
    let rows = statement.query_map([kind.as_str()], |row| row.get::<_, String>(0))?;
    rows.collect()
}

pub fn list(connection: &Connection, kind: MediaKind) -> rusqlite::Result<Vec<Favorite>> {
    Ok(decode_all(data_of(connection, kind)?))
}

pub fn exists(
    connection: &Connection,
    kind: MediaKind,
    media: &MediaRef,
) -> rusqlite::Result<bool> {
    let found: i64 = connection.query_row(
        "SELECT COUNT(*) FROM favorite WHERE kind = ?1 AND media_key = ?2",
        params![kind.as_str(), media_key(media)?],
        |row| row.get(0),
    )?;
    Ok(found > 0)
}

pub fn toggle(
    connection: &mut Connection,
    input: FavoriteInput,
    now_secs: u64,
) -> rusqlite::Result<bool> {
    let transaction = connection.transaction()?;
    let key = media_key(&input.media)?;
    let removed = transaction.execute(
        "DELETE FROM favorite WHERE kind = ?1 AND media_key = ?2",
        params![input.kind.as_str(), key],
    )?;
    if removed > 0 {
        transaction.commit()?;
        return Ok(false);
    }
    let kind = input.kind.as_str();
    let favorite = Favorite::added(input, now_secs);
    transaction.execute(
        "INSERT INTO favorite(kind, media_key, added_at, data) VALUES (?1, ?2, ?3, ?4)",
        params![kind, key, now_secs as i64, encode(&favorite)?],
    )?;
    transaction.commit()?;
    Ok(true)
}
