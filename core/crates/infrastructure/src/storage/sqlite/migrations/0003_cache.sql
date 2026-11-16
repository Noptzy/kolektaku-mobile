CREATE TABLE cache_entry (
    grp TEXT NOT NULL,
    key TEXT NOT NULL,
    body BLOB NOT NULL,
    stored_at INTEGER NOT NULL,
    used_at INTEGER NOT NULL,
    size INTEGER NOT NULL,
    PRIMARY KEY (grp, key)
);
CREATE INDEX cache_by_use ON cache_entry (used_at);
