use domain::library::{Progress, ProgressInput};
use domain::media::{MediaKind, MediaRef};
use rusqlite::{Connection, params};

use super::rows::{decode_all, encode, media_key};

const SAME_UNIT: &str = "ABS(unit - ?3) < 1e-9";

fn texts(
    connection: &Connection,
    sql: &str,
    arguments: impl rusqlite::Params,
) -> rusqlite::Result<Vec<String>> {
    let mut statement = connection.prepare(sql)?;
    let rows = statement.query_map(arguments, |row| row.get::<_, String>(0))?;
    rows.collect()
}

pub fn list(connection: &Connection, kind: MediaKind) -> rusqlite::Result<Vec<Progress>> {
    let rows = texts(
        connection,
        "SELECT data FROM progress WHERE kind = ?1 ORDER BY updated_at DESC, rowid ASC",
        [kind.as_str()],
    )?;
    Ok(decode_all(rows))
}

pub fn save(connection: &mut Connection, input: ProgressInput) -> rusqlite::Result<()> {
    if !input.is_storable() {
        return Ok(());
    }
    let transaction = connection.transaction()?;
    let (kind, key) = (input.kind.as_str(), media_key(&input.media)?);
    transaction.execute(
        &format!("DELETE FROM progress WHERE kind = ?1 AND media_key = ?2 AND {SAME_UNIT}"),
        params![kind, key, input.unit_number],
    )?;
    let progress = Progress::from_input(input);
    transaction.execute(
        "INSERT INTO progress(kind, media_key, unit, updated_at, data) \
         VALUES (?1, ?2, ?3, ?4, ?5)",
        params![
            kind,
            key,
            progress.entry.unit_number,
            progress.entry.updated_at_secs as i64,
            encode(&progress)?
        ],
    )?;
    transaction.commit()
}

pub fn find(
    connection: &Connection,
    kind: MediaKind,
    media: &MediaRef,
    unit: f64,
) -> rusqlite::Result<Option<Progress>> {
    let sql = format!(
        "SELECT data FROM progress WHERE kind = ?1 AND media_key = ?2 AND {SAME_UNIT} LIMIT 1"
    );
    let rows = texts(
        connection,
        &sql,
        params![kind.as_str(), media_key(media)?, unit],
    )?;
    Ok(decode_all(rows).into_iter().next())
}

pub fn last(
    connection: &Connection,
    kind: MediaKind,
    media: &MediaRef,
) -> rusqlite::Result<Option<Progress>> {
    let rows = texts(
        connection,
        "SELECT data FROM progress WHERE kind = ?1 AND media_key = ?2 \
         ORDER BY updated_at DESC, rowid DESC LIMIT 1",
        params![kind.as_str(), media_key(media)?],
    )?;
    Ok(decode_all(rows).into_iter().next())
}

pub fn remove(
    connection: &Connection,
    kind: MediaKind,
    media: &MediaRef,
    unit: f64,
) -> rusqlite::Result<()> {
    connection.execute(
        &format!("DELETE FROM progress WHERE kind = ?1 AND media_key = ?2 AND {SAME_UNIT}"),
        params![kind.as_str(), media_key(media)?, unit],
    )?;
    Ok(())
}

pub fn clear(connection: &Connection, kind: MediaKind) -> rusqlite::Result<()> {
    connection.execute("DELETE FROM progress WHERE kind = ?1", [kind.as_str()])?;
    Ok(())
}
