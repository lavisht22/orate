CREATE TABLE IF NOT EXISTS keys (
  api_key TEXT PRIMARY KEY,
  words_remaining INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS recharges (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  api_key TEXT NOT NULL REFERENCES keys(api_key),
  words_added INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS usage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  api_key TEXT NOT NULL REFERENCES keys(api_key),
  words_used INTEGER NOT NULL,
  audio_duration_ms INTEGER,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_recharges_api_key ON recharges(api_key);
CREATE INDEX IF NOT EXISTS idx_usage_api_key ON usage(api_key);
