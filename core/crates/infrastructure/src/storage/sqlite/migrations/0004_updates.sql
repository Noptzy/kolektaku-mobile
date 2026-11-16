CREATE TABLE unit_snapshot (
    kind TEXT NOT NULL,
    media_key TEXT NOT NULL,
    latest REAL NOT NULL,
    checked_at INTEGER NOT NULL,
    PRIMARY KEY (kind, media_key)
);
