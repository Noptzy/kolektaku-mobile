CREATE TABLE source_link (
    media_key TEXT NOT NULL,
    source TEXT NOT NULL,
    position INTEGER NOT NULL,
    data TEXT NOT NULL,
    PRIMARY KEY (media_key, source)
);
