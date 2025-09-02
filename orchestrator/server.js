import express from 'express';
import bodyParser from 'body-parser';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration
const MCP_DATABASE_MODE = process.env.MCP_DATABASE_MODE || 'local';
const MCP_D1_DATABASE_URL = process.env.MCP_D1_DATABASE_URL;
const MCP_AUTH_KEY = process.env.MCP_AUTH_KEY;

console.log(`🔧 Orchestrator starting in ${MCP_DATABASE_MODE} mode`);

// Middleware
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '10mb' }));

// CORS for development
app.use((req, res, next) => {
  const allowedOrigins = (process.env.ALLOWED_WEB_ORIGINS || 'http://localhost:3080,http://localhost:3000').split(',');
  const origin = req.headers.origin;
  if (allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
    return;
  }
  next();
});

// Remote MCP API proxy functions
async function callRemoteMCP(endpoint, data) {
  if (!MCP_D1_DATABASE_URL) {
    throw new Error('MCP_D1_DATABASE_URL not configured for remote mode');
  }
  
  const response = await fetch(`${MCP_D1_DATABASE_URL}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(MCP_AUTH_KEY ? { 'Authorization': `Bearer ${MCP_AUTH_KEY}` } : {})
    },
    body: JSON.stringify(data)
  });
  
  if (!response.ok) {
    throw new Error(`Remote MCP call failed: ${response.status} ${response.statusText}`);
  }
  
  return await response.json();
}

// Database initialization (only for local mode)
let db;
async function initDatabase() {
  if (MCP_DATABASE_MODE === 'remote') {
    console.log('🌐 Using remote D1 database - skipping local database initialization');
    return;
  }
  
  try {
    const dbFile = process.env.DB_FILE || '/app/data/voygen.sqlite';
    const schemaFile = process.env.SCHEMA_FILE || '/app/db/d1.sql';
    
    // Ensure data directory exists
    const dataDir = path.dirname(dbFile);
    await fs.mkdir(dataDir, { recursive: true });
    
    // Open database
    db = await open({
      filename: dbFile,
      driver: sqlite3.Database
    });
    
    console.log(`📁 Local database opened: ${dbFile}`);
    
    // Initialize schema if it doesn't exist
    try {
      await db.get("SELECT name FROM sqlite_master WHERE type='table' AND name='trips'");
    } catch (error) {
      console.log('Initializing database schema...');
      const schema = await fs.readFile(schemaFile, 'utf8');
      await db.exec(schema);
      console.log('Database schema initialized');
    }
    
    // Enable foreign keys
    await db.exec('PRAGMA foreign_keys = ON');
    
  } catch (error) {
    console.error('Database initialization error:', error);
    process.exit(1);
  }
}

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    ok: true, 
    service: 'voygent-orchestrator',
    version: '0.1.0',
    mode: MCP_DATABASE_MODE,
    remote_url: MCP_DATABASE_MODE === 'remote' ? MCP_D1_DATABASE_URL : null,
    timestamp: new Date().toISOString()
  });
});

// Trip management endpoints
app.get('/api/trips', async (req, res) => {
  try {
    if (MCP_DATABASE_MODE === 'remote') {
      // Use remote D1 database via MCP
      const result = await callRemoteMCP('/mcp/call', {
        method: 'get_anything',
        params: { query: 'all trips', include_everything: true }
      });
      res.json({ trips: result.data || [] });
    } else {
      // Use local database
      const trips = await db.all('SELECT * FROM trips ORDER BY created_at DESC');
      res.json({ trips });
    }
  } catch (error) {
    console.error('Error fetching trips:', error);
    res.status(500).json({ error: 'Failed to fetch trips' });
  }
});

app.post('/api/trips', async (req, res) => {
  try {
    const { id, title, party, destinations } = req.body;
    const tripId = id || `trip_${Date.now()}`;
    
    if (MCP_DATABASE_MODE === 'remote') {
      // Use remote D1 database via MCP
      const result = await callRemoteMCP('/mcp/call', {
        method: 'create_trip_with_client',
        params: {
          trip_name: title,
          destinations: destinations,
          client_email: `${tripId}@voygentce.local`,
          client_full_name: party?.[0]?.name || 'VoygentCE User',
          start_date: new Date().toISOString().split('T')[0],
          end_date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
        }
      });
      res.json({ ok: true, trip_id: result.trip_id || tripId });
    } else {
      // Use local database
      await db.run(
        'INSERT INTO trips (id, title, party, destinations, created_at) VALUES (?, ?, ?, ?, datetime("now"))',
        tripId, title, JSON.stringify(party), destinations
      );
      res.json({ ok: true, trip_id: tripId });
    }
  } catch (error) {
    console.error('Error creating trip:', error);
    res.status(500).json({ error: 'Failed to create trip' });
  }
});

// Hotel ingestion endpoint
app.post('/api/ingest/hotels', async (req, res) => {
  try {
    const { trip_id, city, hotels, site, session_id } = req.body;
    
    if (!trip_id || !hotels || !Array.isArray(hotels)) {
      return res.status(400).json({ error: 'Missing required fields: trip_id, hotels' });
    }
    
    if (MCP_DATABASE_MODE === 'remote') {
      // Use remote D1 database via MCP
      const result = await callRemoteMCP('/mcp/call', {
        method: 'ingest_hotels',
        params: {
          trip_id,
          hotels,
          site: site || 'voygentce',
          session_id
        }
      });
      res.json({ 
        ok: true, 
        ingested: hotels.length,
        trip_id,
        city,
        remote: true
      });
    } else {
      // Use local database
      for (const hotel of hotels) {
        await db.run(
          `INSERT INTO hotel_cache (trip_id, city, site, hotel_data, lead_price, ingested_at) 
           VALUES (?, ?, ?, ?, ?, datetime("now"))`,
          trip_id, 
          city || hotel.city, 
          site || hotel.site,
          JSON.stringify(hotel),
          hotel.lead_price?.amount || 0
        );
      }
      
      // Mark trip facts as dirty
      await db.run(
        'UPDATE trips SET facts_dirty = 1, updated_at = datetime("now") WHERE id = ?',
        trip_id
      );
      
      res.json({ 
        ok: true, 
        ingested: hotels.length,
        trip_id,
        city 
      });
    }
    
    console.log(`Ingested ${hotels.length} hotels for trip ${trip_id}, city ${city}`);
    
  } catch (error) {
    console.error('Error ingesting hotels:', error);
    res.status(500).json({ error: 'Failed to ingest hotels' });
  }
});

// Room ingestion endpoint
app.post('/api/ingest/rooms', async (req, res) => {
  try {
    const { trip_id, rooms_by_hotel, site } = req.body;
    
    if (!trip_id || !rooms_by_hotel) {
      return res.status(400).json({ error: 'Missing required fields: trip_id, rooms_by_hotel' });
    }
    
    let totalRooms = 0;
    for (const hotelRooms of rooms_by_hotel) {
      const { hotel_key, rooms } = hotelRooms;
      
      for (const room of rooms) {
        await db.run(
          `INSERT INTO room_cache (trip_id, hotel_key, site, room_data, total_price, ingested_at)
           VALUES (?, ?, ?, ?, ?, datetime("now"))`,
          trip_id,
          hotel_key,
          site,
          JSON.stringify(room),
          room.total || 0
        );
        totalRooms++;
      }
    }
    
    // Mark trip facts as dirty
    await db.run(
      'UPDATE trips SET facts_dirty = 1, updated_at = datetime("now") WHERE id = ?',
      trip_id
    );
    
    console.log(`Ingested ${totalRooms} rooms for trip ${trip_id}`);
    res.json({ 
      ok: true, 
      ingested: totalRooms,
      trip_id 
    });
    
  } catch (error) {
    console.error('Error ingesting rooms:', error);
    res.status(500).json({ error: 'Failed to ingest rooms' });
  }
});

// Facts refresh endpoint
app.post('/api/facts/refresh/:tripId', async (req, res) => {
  try {
    const { tripId } = req.params;
    
    if (MCP_DATABASE_MODE === 'remote') {
      // Use remote D1 database via MCP
      const result = await callRemoteMCP('/mcp/call', {
        method: 'refresh_trip_facts',
        params: { trip_id: tripId }
      });
      res.json({ 
        ok: true, 
        trip_id: tripId,
        remote: true,
        ...result
      });
    } else {
      // Use local database
      const trip = await db.get('SELECT * FROM trips WHERE id = ?', tripId);
      if (!trip) {
        return res.status(404).json({ error: 'Trip not found' });
      }
      
      // Get hotel data
      const hotels = await db.all(
        'SELECT * FROM hotel_cache WHERE trip_id = ? ORDER BY lead_price ASC',
        tripId
      );
      
      // Get room data
      const rooms = await db.all(
        'SELECT * FROM room_cache WHERE trip_id = ?',
        tripId
      );
      
      // Build facts JSON
      const facts = {
        trip_id: tripId,
        title: trip.title,
        destinations: trip.destinations,
        party: JSON.parse(trip.party || '[]'),
        hotels: hotels.map(h => JSON.parse(h.hotel_data)),
        rooms: rooms.map(r => JSON.parse(r.room_data)),
        stats: {
          total_hotels: hotels.length,
          total_rooms: rooms.length,
          min_price: hotels[0]?.lead_price || 0,
          max_price: hotels[hotels.length - 1]?.lead_price || 0
        },
        refreshed_at: new Date().toISOString()
      };
      
      // Calculate lead price min
      const leadPriceMin = hotels.length > 0 ? hotels[0].lead_price : null;
      
      // Update or insert trip facts
      await db.run(
        `INSERT OR REPLACE INTO trip_facts (trip_id, facts, lead_price_min, updated_at)
         VALUES (?, ?, ?, datetime("now"))`,
        tripId,
        JSON.stringify(facts),
        leadPriceMin
      );
      
      // Clear dirty flag
      await db.run(
        'UPDATE trips SET facts_dirty = 0, updated_at = datetime("now") WHERE id = ?',
        tripId
      );
      
      res.json({ 
        ok: true, 
        trip_id: tripId,
        stats: facts.stats
      });
    }
    
    console.log(`Facts refreshed for trip ${tripId} (${MCP_DATABASE_MODE} mode)`);
    
  } catch (error) {
    console.error('Error refreshing facts:', error);
    res.status(500).json({ error: 'Failed to refresh facts' });
  }
});

// Facts query endpoint
app.post('/api/facts/query', async (req, res) => {
  try {
    const { city, max_lead_price, refundable, min_rating, trip_id } = req.body;
    
    let query = 'SELECT * FROM trip_facts WHERE 1=1';
    const params = [];
    
    if (trip_id) {
      query += ' AND trip_id = ?';
      params.push(trip_id);
    }
    
    if (max_lead_price) {
      query += ' AND lead_price_min <= ?';
      params.push(max_lead_price);
    }
    
    query += ' ORDER BY updated_at DESC';
    
    const results = await db.all(query, params);
    
    // Filter by additional criteria in JSON facts
    const filtered = results.filter(row => {
      const facts = JSON.parse(row.facts);
      
      if (city) {
        const hasCity = facts.hotels?.some(h => 
          h.city?.toLowerCase().includes(city.toLowerCase())
        );
        if (!hasCity) return false;
      }
      
      if (refundable !== undefined) {
        const hasRefundable = facts.hotels?.some(h => h.refundable === refundable);
        if (!hasRefundable) return false;
      }
      
      return true;
    });
    
    res.json({ 
      results: filtered.map(row => ({
        trip_id: row.trip_id,
        facts: JSON.parse(row.facts),
        lead_price_min: row.lead_price_min,
        updated_at: row.updated_at
      }))
    });
    
  } catch (error) {
    console.error('Error querying facts:', error);
    res.status(500).json({ error: 'Failed to query facts' });
  }
});

// L/M/H recommendations endpoint
app.post('/api/plan/city', async (req, res) => {
  try {
    const { trip_id, city, prefs = {} } = req.body;
    
    if (!trip_id || !city) {
      return res.status(400).json({ error: 'Missing required fields: trip_id, city' });
    }
    
    // Get hotels for this city
    const hotels = await db.all(
      `SELECT hotel_data, lead_price FROM hotel_cache 
       WHERE trip_id = ? AND (city = ? OR hotel_data LIKE ?)
       ORDER BY lead_price ASC`,
      trip_id, city, `%"city":"${city}"%`
    );
    
    if (hotels.length === 0) {
      return res.json({ 
        ok: true,
        city,
        recommendations: { low: null, medium: null, high: null },
        message: 'No hotels found for this city'
      });
    }
    
    // Parse hotel data and filter by preferences
    const hotelData = hotels.map(h => JSON.parse(h.hotel_data))
      .filter(hotel => {
        if (prefs.refundable !== undefined && hotel.refundable !== prefs.refundable) {
          return false;
        }
        if (prefs.max_price && hotel.lead_price?.amount > prefs.max_price) {
          return false;
        }
        return true;
      });
    
    // Select L/M/H recommendations
    const count = hotelData.length;
    const recommendations = {
      low: count > 0 ? hotelData[0] : null,
      medium: count > 1 ? hotelData[Math.floor(count * 0.5)] : null,
      high: count > 2 ? hotelData[count - 1] : null
    };
    
    res.json({ 
      ok: true,
      city,
      total_options: count,
      recommendations 
    });
    
  } catch (error) {
    console.error('Error planning city:', error);
    res.status(500).json({ error: 'Failed to plan city' });
  }
});

// Simple proposal rendering endpoint
app.post('/api/proposal/render', async (req, res) => {
  try {
    const { trip_id, template = 'basic', output_format = 'html' } = req.body;
    
    // Get trip facts
    const tripFacts = await db.get('SELECT * FROM trip_facts WHERE trip_id = ?', trip_id);
    if (!tripFacts) {
      return res.status(404).json({ error: 'Trip facts not found. Run refresh first.' });
    }
    
    const facts = JSON.parse(tripFacts.facts);
    
    // Simple HTML template
    const html = `
<!DOCTYPE html>
<html>
<head>
    <title>Travel Proposal: ${facts.title || trip_id}</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; border-bottom: 2px solid #333; padding-bottom: 20px; }
        .section { margin: 30px 0; }
        .hotel { border: 1px solid #ddd; margin: 10px 0; padding: 15px; border-radius: 5px; }
        .price { font-weight: bold; color: #2a5aa0; }
        .stats { background: #f5f5f5; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Travel Proposal</h1>
        <h2>${facts.title || trip_id}</h2>
        <p>Destinations: ${facts.destinations || 'Not specified'}</p>
    </div>
    
    <div class="section">
        <h3>Trip Overview</h3>
        <div class="stats">
            <p><strong>Total Hotels Found:</strong> ${facts.stats?.total_hotels || 0}</p>
            <p><strong>Price Range:</strong> $${facts.stats?.min_price || 0} - $${facts.stats?.max_price || 0}</p>
            <p><strong>Total Room Options:</strong> ${facts.stats?.total_rooms || 0}</p>
        </div>
    </div>
    
    <div class="section">
        <h3>Hotel Options</h3>
        ${facts.hotels?.slice(0, 5).map(hotel => `
            <div class="hotel">
                <h4>${hotel.name || 'Hotel Name'}</h4>
                <p><strong>Location:</strong> ${hotel.city || 'Location'}</p>
                <p><strong>Lead Price:</strong> <span class="price">$${hotel.lead_price?.amount || 0} ${hotel.lead_price?.currency || 'USD'}</span></p>
                <p><strong>Refundable:</strong> ${hotel.refundable ? 'Yes' : 'No'}</p>
                <p><strong>Source:</strong> ${hotel.site || 'Unknown'}</p>
            </div>
        `).join('') || '<p>No hotels available</p>'}
    </div>
    
    <div class="section">
        <p><em>Proposal generated on ${new Date().toLocaleDateString()} by VoygentCE</em></p>
    </div>
</body>
</html>`;
    
    res.json({ 
      ok: true,
      trip_id,
      format: output_format,
      content: html,
      generated_at: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Error rendering proposal:', error);
    res.status(500).json({ error: 'Failed to render proposal' });
  }
});

// Error handling
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
async function start() {
  await initDatabase();
  
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`VoygentCE Orchestrator running on port ${PORT}`);
    console.log(`Health check: http://localhost:${PORT}/health`);
  });
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  if (db) await db.close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, shutting down gracefully');
  if (db) await db.close();
  process.exit(0);
});

start().catch(error => {
  console.error('Failed to start server:', error);
  process.exit(1);
});