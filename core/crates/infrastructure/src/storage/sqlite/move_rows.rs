use domain::library::{Favorite, Progress};
use domain::media::{MediaKind, MediaRef};
use rusqlite::{Connection, Transaction, params};

use super::rows::{decode_all, encode, media_key};

fn texts(transaction: &Transaction, sql: &str, kind: MediaKind) -> rusqlite::Result<Vec<String>> {
    let mut statement = transaction.prepare(sql)?;
    let rows = statement.query_map([kind.as_str()], |row| row.get::<_, String>(0))?;
    rows.collect()
}

fn moved_favorites(
    transaction: &Transaction,
    from: MediaKind,
    to: MediaKind,
    wanted: &[String],
) -> rusqlite::Result<usize> {
    let rows = texts(
        transaction,
        "SELECT data FROM favorite WHERE kind = ?1",
        from,
    )?;
    let mut moved = 0;
    for mut favorite in decode_all::<Favorite>(rows) {
        let key = media_key(&favorite.entry.media)?;
        if !wanted.contains(&key) {
            continue;
        }
        transaction.execute(
            "DELETE FROM favorite WHERE kind = ?1 AND media_key = ?2",
            params![from.as_str(), key],
        )?;
        favorite.entry.kind = to;
        transaction.execute(
            "INSERT OR REPLACE INTO favorite(kind, media_key, added_at, data) \
             VALUES (?1, ?2, ?3, ?4)",
            params![
                to.as_str(),
                key,
                favorite.added_at_secs as i64,
                encode(&favorite)?
            ],
        )?;
        moved += 1;
    }
    Ok(moved)
}

fn moved_history(
    transaction: &Transaction,
    from: MediaKind,
    to: MediaKind,
    wanted: &[String],
) -> rusqlite::Result<usize> {
    let rows = texts(
        transaction,
        "SELECT data FROM progress WHERE kind = ?1",
        from,
    )?;
    let mut moved = 0;
    for mut progress in decode_all::<Progress>(rows) {
        let key = media_key(&progress.entry.media)?;
        if !wanted.contains(&key) {
            continue;
        }
        transaction.execute(
            "DELETE FROM progress WHERE kind = ?1 AND media_key = ?2 AND ABS(unit - ?3) < 1e-9",
            params![from.as_str(), key, progress.entry.unit_number],
        )?;
        progress.entry.kind = to;
        transaction.execute(
            "INSERT INTO progress(kind, media_key, unit, updated_at, data) \
             VALUES (?1, ?2, ?3, ?4, ?5)",
            params![
                to.as_str(),
                key,
                progress.entry.unit_number,
                progress.entry.updated_at_secs as i64,
                encode(&progress)?
            ],
        )?;
        moved += 1;
    }
    Ok(moved)
}

fn moved_orders(
    transaction: &Transaction,
    from: MediaKind,
    to: MediaKind,
    wanted: &[String],
) -> rusqlite::Result<usize> {
    let mut moved = 0;
    for key in wanted {
        moved += transaction.execute(
            "UPDATE OR REPLACE unit_order SET kind = ?1 WHERE kind = ?2 AND media_key = ?3",
            params![to.as_str(), from.as_str(), key],
        )?;
    }
    Ok(moved)
}

pub fn move_entries(
    connection: &mut Connection,
    from: MediaKind,
    to: MediaKind,
    media: &[MediaRef],
) -> rusqlite::Result<usize> {
    let wanted: Vec<String> = media.iter().map(media_key).collect::<Result<_, _>>()?;
    let transaction = connection.transaction()?;
    let moved = moved_favorites(&transaction, from, to, &wanted)?
        + moved_history(&transaction, from, to, &wanted)?
        + moved_orders(&transaction, from, to, &wanted)?;
    transaction.commit()?;
    Ok(moved)
}
