use rusqlite::Connection;

const MIGRATIONS: [&str; 6] = [
    include_str!("migrations/0001_library.sql"),
    include_str!("migrations/0002_source_links.sql"),
    include_str!("migrations/0003_cache.sql"),
    include_str!("migrations/0004_updates.sql"),
    include_str!("migrations/0005_highlights.sql"),
    include_str!("migrations/0006_downloads.sql"),
];

#[cfg(test)]
pub fn latest_version() -> usize {
    MIGRATIONS.len()
}

pub fn migrate(connection: &mut Connection) -> rusqlite::Result<()> {
    let current: i64 = connection.query_row("PRAGMA user_version", [], |row| row.get(0))?;
    for (index, sql) in MIGRATIONS.iter().enumerate().skip(current as usize) {
        let transaction = connection.transaction()?;
        transaction.execute_batch(sql)?;
        transaction.pragma_update(None, "user_version", (index + 1) as i64)?;
        transaction.commit()?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn version(connection: &Connection) -> usize {
        let value: i64 = connection
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        value as usize
    }

    #[test]
    fn a_fresh_database_gets_every_migration_in_order() {
        let mut connection = Connection::open_in_memory().unwrap();
        migrate(&mut connection).unwrap();
        assert_eq!(version(&connection), latest_version());
        for table in [
            "favorite",
            "progress",
            "preference",
            "source_link",
            "cache_entry",
            "unit_snapshot",
        ] {
            let found: i64 = connection
                .query_row(
                    "SELECT COUNT(*) FROM sqlite_master WHERE name = ?1",
                    [table],
                    |row| row.get(0),
                )
                .unwrap();
            assert_eq!(found, 1, "{table}");
        }
    }

    #[test]
    fn running_again_changes_nothing() {
        let mut connection = Connection::open_in_memory().unwrap();
        migrate(&mut connection).unwrap();
        migrate(&mut connection).unwrap();
        assert_eq!(version(&connection), latest_version());
    }

    #[test]
    fn an_older_database_is_brought_up_to_date_without_losing_rows() {
        let mut connection = Connection::open_in_memory().unwrap();
        let transaction = connection.transaction().unwrap();
        transaction.execute_batch(MIGRATIONS[0]).unwrap();
        transaction.pragma_update(None, "user_version", 1).unwrap();
        transaction.commit().unwrap();
        connection
            .execute(
                "INSERT INTO preference(name, value) VALUES ('keep', 'me')",
                [],
            )
            .unwrap();
        migrate(&mut connection).unwrap();
        let kept: String = connection
            .query_row(
                "SELECT value FROM preference WHERE name='keep'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(kept, "me");
        assert_eq!(version(&connection), latest_version());
    }

    #[test]
    fn a_failing_migration_leaves_the_version_where_it_was() {
        let mut connection = Connection::open_in_memory().unwrap();
        let transaction = connection.transaction().unwrap();
        let broken = transaction.execute_batch("CREATE TABLE ok(x); CREATE TABLE ok(x);");
        assert!(broken.is_err());
        drop(transaction);
        assert_eq!(version(&connection), 0);
    }
}
