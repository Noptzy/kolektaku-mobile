CREATE TABLE highlight (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    media_key TEXT NOT NULL,
    chapter REAL NOT NULL,
    block INTEGER NOT NULL,
    start INTEGER NOT NULL,
    end INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    data TEXT NOT NULL
);
CREATE INDEX highlight_by_chapter ON highlight (media_key, chapter);
