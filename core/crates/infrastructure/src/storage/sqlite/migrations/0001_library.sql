CREATE TABLE favorite (
    kind TEXT NOT NULL,
    media_key TEXT NOT NULL,
    added_at INTEGER NOT NULL,
    data TEXT NOT NULL,
    PRIMARY KEY (kind, media_key)
);

CREATE TABLE progress (
    kind TEXT NOT NULL,
    media_key TEXT NOT NULL,
    unit REAL NOT NULL,
    updated_at INTEGER NOT NULL,
    data TEXT NOT NULL
);
CREATE INDEX progress_by_media ON progress (kind, media_key, unit);

CREATE TABLE unit_order (
    kind TEXT NOT NULL,
    media_key TEXT NOT NULL,
    data TEXT NOT NULL,
    PRIMARY KEY (kind, media_key)
);

CREATE TABLE preference (
    name TEXT PRIMARY KEY NOT NULL,
    value TEXT NOT NULL
);

CREATE TABLE search_history (
    kind TEXT NOT NULL,
    position INTEGER NOT NULL,
    query TEXT NOT NULL,
    PRIMARY KEY (kind, position)
);
