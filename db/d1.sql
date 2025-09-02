-- VoygentCE Database Schema
-- Compatible with SQLite, D1, and PostgreSQL
-- Version: 1.0

PRAGMA foreign_keys = ON;

-- Core trips table
CREATE TABLE IF NOT EXISTS trips (
    id TEXT PRIMARY KEY,
    title TEXT,
    party TEXT, -- JSON array of travelers
    destinations TEXT,
    start_date TEXT,
    end_date TEXT,
    status TEXT DEFAULT 'planning',
    facts_dirty INTEGER DEFAULT 0,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

-- Trip legs (city segments)
CREATE TABLE IF NOT EXISTS trip_legs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id TEXT REFERENCES trips(id) ON DELETE CASCADE,
    city TEXT NOT NULL,
    arrive_date TEXT,
    nights INTEGER,
    preferences TEXT, -- JSON preferences
    created_at TEXT DEFAULT (datetime('now'))
);

-- Trip facts (denormalized for LLM queries)
CREATE TABLE IF NOT EXISTS trip_facts (
    trip_id TEXT PRIMARY KEY REFERENCES trips(id) ON DELETE CASCADE,
    facts TEXT NOT NULL, -- Complete JSON facts document
    lead_price_min REAL,
    hotel_count INTEGER DEFAULT 0,
    room_count INTEGER DEFAULT 0,
    updated_at TEXT DEFAULT (datetime('now'))
);

-- Hotel cache (raw ingested data)
CREATE TABLE IF NOT EXISTS hotel_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    city TEXT,
    site TEXT, -- navitrip, trisept, vax, etc.
    hotel_data TEXT NOT NULL, -- Full JSON hotel object
    lead_price REAL,
    ingested_at TEXT DEFAULT (datetime('now'))
);

-- Room cache (room-level pricing data)
CREATE TABLE IF NOT EXISTS room_cache (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    hotel_key TEXT, -- Hotel identifier (GIATA ID or site-specific)
    site TEXT,
    room_data TEXT NOT NULL, -- Full JSON room object
    total_price REAL,
    ingested_at TEXT DEFAULT (datetime('now'))
);

-- Commission configuration
CREATE TABLE IF NOT EXISTS commission_rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    site TEXT NOT NULL,
    rate_type TEXT NOT NULL, -- 'percentage', 'fixed'
    rate_value REAL NOT NULL,
    min_booking REAL DEFAULT 0,
    max_booking REAL,
    refundable_bonus REAL DEFAULT 0,
    effective_from TEXT DEFAULT (datetime('now')),
    effective_to TEXT,
    active INTEGER DEFAULT 1
);

-- Extraction sessions (track browser automation)
CREATE TABLE IF NOT EXISTS extraction_sessions (
    id TEXT PRIMARY KEY,
    trip_id TEXT REFERENCES trips(id) ON DELETE CASCADE,
    site TEXT NOT NULL,
    status TEXT DEFAULT 'active', -- active, completed, failed
    search_params TEXT, -- JSON search parameters
    results_count INTEGER DEFAULT 0,
    started_at TEXT DEFAULT (datetime('now')),
    completed_at TEXT,
    error_message TEXT
);

-- Generated proposals
CREATE TABLE IF NOT EXISTS proposals (
    id TEXT PRIMARY KEY,
    trip_id TEXT NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    title TEXT,
    template_used TEXT DEFAULT 'basic',
    html_content TEXT,
    pdf_path TEXT,
    generated_at TEXT DEFAULT (datetime('now')),
    generated_by TEXT DEFAULT 'system'
);

-- Activity log (for debugging and audit)
CREATE TABLE IF NOT EXISTS activity_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id TEXT,
    action TEXT NOT NULL,
    details TEXT, -- JSON details
    timestamp TEXT DEFAULT (datetime('now')),
    ip_address TEXT,
    user_agent TEXT
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_created ON trips(created_at);
CREATE INDEX IF NOT EXISTS idx_trip_legs_trip_id ON trip_legs(trip_id);
CREATE INDEX IF NOT EXISTS idx_hotel_cache_trip_id ON hotel_cache(trip_id);
CREATE INDEX IF NOT EXISTS idx_hotel_cache_city ON hotel_cache(city);
CREATE INDEX IF NOT EXISTS idx_hotel_cache_price ON hotel_cache(lead_price);
CREATE INDEX IF NOT EXISTS idx_room_cache_trip_id ON room_cache(trip_id);
CREATE INDEX IF NOT EXISTS idx_extraction_sessions_trip_id ON extraction_sessions(trip_id);
CREATE INDEX IF NOT EXISTS idx_extraction_sessions_status ON extraction_sessions(status);
CREATE INDEX IF NOT EXISTS idx_proposals_trip_id ON proposals(trip_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_trip_id ON activity_log(trip_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_timestamp ON activity_log(timestamp);

-- Triggers to maintain data consistency
CREATE TRIGGER IF NOT EXISTS tr_trips_updated 
AFTER UPDATE ON trips
BEGIN
    UPDATE trips SET updated_at = datetime('now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS tr_hotel_cache_facts_dirty
AFTER INSERT ON hotel_cache
BEGIN
    UPDATE trips SET facts_dirty = 1, updated_at = datetime('now') WHERE id = NEW.trip_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_room_cache_facts_dirty
AFTER INSERT ON room_cache
BEGIN
    UPDATE trips SET facts_dirty = 1, updated_at = datetime('now') WHERE id = NEW.trip_id;
END;

-- Sample data for testing (uncomment if needed)
/*
INSERT INTO trips (id, title, party, destinations) VALUES 
('demo_trip_1', 'Paris Getaway Demo', '[{"name":"Demo User","role":"traveler"}]', 'Paris, France');

INSERT INTO trip_legs (trip_id, city, arrive_date, nights, preferences) VALUES
('demo_trip_1', 'Paris', '2025-06-01', 4, '{"style":"boutique","budget_per_night":275,"refundable":true}');

INSERT INTO commission_rates (site, rate_type, rate_value, refundable_bonus) VALUES
('navitrip', 'percentage', 8.5, 1.5),
('trisept', 'percentage', 10.0, 2.0),
('vax', 'percentage', 7.5, 1.0);
*/

-- Views for common queries
CREATE VIEW IF NOT EXISTS trip_summary AS
SELECT 
    t.id,
    t.title,
    t.destinations,
    t.status,
    t.created_at,
    COUNT(DISTINCT hc.id) as hotel_count,
    COUNT(DISTINCT rc.id) as room_count,
    MIN(hc.lead_price) as min_price,
    MAX(hc.lead_price) as max_price,
    tf.updated_at as facts_updated
FROM trips t
LEFT JOIN hotel_cache hc ON t.id = hc.trip_id
LEFT JOIN room_cache rc ON t.id = rc.trip_id  
LEFT JOIN trip_facts tf ON t.id = tf.trip_id
GROUP BY t.id, t.title, t.destinations, t.status, t.created_at, tf.updated_at;