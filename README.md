# Voygent Community Edition (CE)

> **AI‑first travel proposals** with availability‑aware hotel search, commission‑smart picks, and beautiful client‑facing pages. This is the self‑hosted, bring‑your‑own‑key edition aimed at early adopters and tech‑savvy advisors.

---

## Why Voygent CE?

* **BYOK**: Use your own LLM keys (Anthropic, OpenAI, etc.) - no shared infrastructure costs
* **Own your data**: Run your own database (SQLite/PostgreSQL) with complete data control  
* **Local browser automation**: Keep **mcp‑chrome** on your machine for real-time hotel price extraction
* **Open & scriptable**: Simple HTTP APIs for ingesting search results and rendering proposals
* **Self-contained**: Docker Compose deployment with no external service dependencies

---

## What you get

* **LibreChat Integration**: Professional chat UI with MCP tool integration for travel planning
* **Flexible MCP Architecture**: Choose Local, Remote, or Hybrid server configuration
* **Browser Automation**: Real-time hotel data extraction from booking sites (Navitrip, Trisept, VAX)
* **Orchestrator API**: Trip management, hotel caching, facts processing, and L/M/H recommendations  
* **Proposal Generator**: Beautiful HTML/PDF proposals using Nunjucks templates
* **Hybrid Database**: Normalized tables + LLM‑optimized `trip_facts` for fast AI queries

---

## MCP Server Modes

VoygentCE supports flexible MCP (Model Context Protocol) server configuration:

### 🏠 Local Mode (Default)
- **Fully self-contained** - no external dependencies
- **Complete data ownership** - SQLite/PostgreSQL on your machine  
- **Fastest performance** - no network latency
- **Best for**: Privacy-focused users, offline work

### 🌐 Remote Mode  
- **Connect to existing Cloudflare Workers** - use your d1-database and prompt-instructions servers
- **Shared data** across multiple installations
- **Advanced features** - commission optimization, fact materialization
- **Best for**: Users with existing Voygen infrastructure

### 🔄 Hybrid Mode
- **Mix local and remote** - flexible per-component configuration
- **Keep data local, share workflows** - or vice versa
- **Best for**: Advanced users wanting custom setups

> See the complete [MCP Configuration Guide](docs/MCP_CONFIGURATION.md) for setup details.

---

## Quick Start (5 Minutes)

**Prerequisites**: Docker, Docker Compose, Node.js 18+

```bash
# 1) Clone the repository
git clone https://github.com/iamneilroberts/voygent.appCE.git
cd voygent.appCE

# 2) Copy and configure environment
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY or OPENAI_API_KEY

# 3) Run automated setup
./scripts/setup.sh

# 4) Access the system
open http://localhost:3080  # LibreChat UI
```

**That's it!** Your VoygentCE system is now running with:
- LibreChat UI at `http://localhost:3080`
- Orchestrator API at `http://localhost:3000` (if using local mode)
- MongoDB, MeiliSearch, and all configured services

> The setup script will prompt you to choose between **Local**, **Remote**, or **Hybrid** MCP modes. See [MCP Configuration Guide](docs/MCP_CONFIGURATION.md) for details.

**Services**

* `proxy` – Caddy reverse proxy (TLS optional in local dev)
* `librechat` – chat UI/API
* `orchestrator` – CE backend (Express)
* `postgres` or `sqlite` – choose one (SQLite is default for quick local runs)

> If you prefer pure local without Docker, skip down to **Manual Install**.

---

## Directory layout

```
voygent-ce/
  orchestrator/
    src/
    server.js
  librechat/
    (pulled image)
  db/
    d1.sql           # CE schema (works with SQLite/D1/Neon)
  data/
    (db files, assets)
  templates/
    proposal.njk
  docker-compose.yml
  Caddyfile
  .env.example
```

## docker-compose.yml (starter)
version: '3.9'
services:
  orchestrator:
    build: ./orchestrator
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./data:/app/data
    depends_on:
      - postgres

  librechat:
    image: dannyavila/librechat:latest
    restart: unless-stopped
    env_file: .env

  postgres:
    image: postgres:15
    restart: unless-stopped
    environment:
      POSTGRES_USER: voygent
      POSTGRES_PASSWORD: voygent
      POSTGRES_DB: voygent
    volumes:
      - ./data/pg:/var/lib/postgresql/data

  proxy:
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config

volumes:
  caddy_data:
  caddy_config:
---

## Orchestrator Example (server.js)
import express from 'express';
import bodyParser from 'body-parser';
import sqlite3 from 'sqlite3';
import { open } from 'sqlite';

const app = express();
app.use(bodyParser.json());

const db = await open({ filename: './data/voygen.sqlite', driver: sqlite3.Database });

app.get('/health', (_, res) => res.json({ ok: true }));

app.post('/api/ingest/hotels', async (req, res) => {
  const { trip_id, city, hotels } = req.body;
  await db.run('insert into ingested_hotels (trip_id, city, hotels) values (?, ?, ?)',
    trip_id, city, JSON.stringify(hotels));
  res.json({ ok: true });
});

app.listen(3000, () => console.log('Orchestrator running on 3000'));

## Configuration (.env)

Helpful keys from `.env.example`:

```ini
# Public hostnames (use localhost in dev)
LIBRECHAT_HOST=localhost
API_HOST=localhost

# Orchestrator
PORT=3000
DB_FILE=/data/voygen.sqlite     # for SQLite
SCHEMA_FILE=/app/../db/d1.sql

# LLM providers (BYOK)
ANTHROPIC_API_KEY=
OPENAI_API_KEY=

# CORS / security
ALLOWED_WEB_ORIGINS=http://localhost:3080,http://localhost:3000
ALLOWED_MCP_ORIGINS=http://localhost:3080
```

**Notes**

* For Postgres/Neon, set `DATABASE_URL=postgres://...` and the orchestrator will prefer that over SQLite.
* `ALLOWED_MCP_ORIGINS` should include the origins where LibreChat runs.

---
### Database Schema (db/db1.sql)
create table if not exists trips (
  id text primary key,
  title text,
  party json
);

create table if not exists trip_legs (
  id integer primary key autoincrement,
  trip_id text references trips(id),
  city text,
  arrive text,
  nights int,
  prefs json
);

create table if not exists trip_facts (
  trip_id text references trips(id),
  facts json,
  lead_price_min numeric,
  updated_at timestamp default current_timestamp
);

create table if not exists ingested_hotels (
  id integer primary key autoincrement,
  trip_id text,
  city text,
  hotels json
);

# additional tables for full trip flow 
# activities (trip_id, day, city, title, supplier, price_pp/total, notes, links)
# transport (trip_id, type: flight|car|transfer, vendor, details json, total)
# financials (trip_id, currency, total, per_person, deposit, due_dates json)

## Database options

### SQLite (default, simplest)

* Zero‑config for development.
* File will be created at `data/voygen.sqlite`.

### Cloudflare D1

* Use Wrangler/HTTP binding to point orchestrator at D1.
* Schema in `db/d1.sql` works as‑is.

### Neon Postgres

* Create a Neon project and a database.
* Set `DATABASE_URL` in `.env`.
* Run `db/d1.sql` (most SQL works; for JSON bits use Postgres JSONB operators where needed).

---

## Manual install (no Docker)

Run this on your machine or a VPS.

```bash
# Orchestrator
cd orchestrator
npm i
# set env vars (or use a .env loader like dotenv-cli)
node server.js

# LibreChat (local)
# See LibreChat docs for local run with your provider keys & MCP tools.
```

**System requirements**

* Node.js 18+
* For PDF export: headless Chrome/Chromium (Puppeteer) if you enable PDF rendering.

---

## Vendor automation (mcp‑chrome)

* Install and run **mcp‑chrome** on the same machine you use to browse vendor sites (CPMaxx/Navitrip/VAX/WAD).
* Your assistant will:

  1. open vendor site, perform a search
  2. extract normalized `HotelOption[]`
  3. POST to `orchestrator` endpoints (below)

**Normalized HotelOption** (example):

```json
{
  "site": "trisept",
  "name": "Hotel du Parc",
  "city": "Paris",
  "lead_price": { "amount": 260, "currency": "USD" },
  "refundable": true,
  "rates": [
    { "label": "Flex", "total": 1040, "refundable": true }
  ],
  "deeplinks": { "select": "https://..." },
  "tags": ["quaint", "walkable"]
}
```

---

## Core endpoints (Orchestrator)

### Health

```http
GET /health → { ok: true }
```

### Ingest hotels

```http
POST /api/ingest/hotels
{
  "trip_id": "trip_1",
  "city": "Paris",
  "hotels": [ HotelOption, ... ]
}
```

### Ingest rooms (per hotel)

```http
POST /api/ingest/rooms
{
  "trip_id": "trip_1",
  "rooms_by_hotel": [
    { "hotel_key": "Hotel du Parc", "rooms": [ {"room_name": "Classic", "total": 880, "refundable": true } ] }
  ]
}
```

### Refresh facts snapshot

```http
POST /api/facts/refresh/:tripId
# builds/updates trip_facts.facts JSON and lead_price_min
```

### Query facts (simple filters)

```http
POST /api/facts/query
{
  "city": "Paris",
  "max_lead_price": 275,
  "refundable": true
}
```

### L/M/H per city

```http
POST /api/plan/city
{
  "trip_id": "trip_1",
  "city": "Paris",
  "prefs": { "refundable": true }
}
```

### Render proposal (optional)

```http
POST /api/proposal/render
{
  "trip_id": "trip_1",
  "template": "proposal.njk",
  "output": "data/proposals/trip_1.html",
  "pdf": false
}
```

---

## Example flow (copy/paste)

```bash
# Insert a trip and leg (SQLite shown)
sqlite3 data/voygen.sqlite "insert into trips (id,title,party) values ('trip_1','Paris Test','[{\"name\":\"Alice\",\"role\":\"traveler\"}]');"
sqlite3 data/voygen.sqlite "insert into trip_legs (trip_id,city,arrive,nights,prefs) values ('trip_1','Paris','2025-06-01',4,'{\"style\":\"quaint_inn\",\"budget_per_night\":275,\"refundable\":true}');"

# Ingest hotels (simplified)
curl -s -X POST http://localhost:3000/api/ingest/hotels \
  -H "content-type: application/json" \
  -d '{
    "trip_id":"trip_1",
    "city":"Paris",
    "hotels":[
      {"site":"trisept","name":"Innis Paris","city":"Paris","lead_price":{"amount":220},"refundable":true,"rates":[{"label":"Std","refundable":true,"total":880}]},
      {"site":"navitrip","name":"Grand Rue","city":"Paris","lead_price":{"amount":290},"refundable":false,"rates":[{"label":"Nonref","refundable":false,"total":1160}]},
      {"site":"vax","name":"Hotel du Parc","city":"Paris","lead_price":{"amount":260},"refundable":true,"rates":[{"label":"Flex","refundable":true,"total":1040}]}
    ]
  }'

# Refresh facts
curl -s -X POST http://localhost:3000/api/facts/refresh/trip_1 | jq

# Picks (L/M/H)
curl -s -X POST http://localhost:3000/api/plan/city \
  -H "content-type: application/json" \
  -d '{"trip_id":"trip_1","city":"Paris","prefs":{"refundable":true}}' | jq

# Query
curl -s -X POST http://localhost:3000/api/facts/query \
  -H "content-type: application/json" \
  -d '{"city":"Paris","max_lead_price":275,"refundable":true}' | jq
```

---

## Prerequisites & dependencies

* **Node.js 18+**
* **Docker** (optional but recommended)
* **mcp‑chrome** (local) for vendor automation
* **LLM provider key(s)** (Anthropic/OpenAI, etc.)
* **Chromium** (optional) for PDF rendering via Puppeteer

Useful links:

* MCP‑Chrome: [https://github.com/hangwin/mcp-chrome](https://github.com/hangwin/mcp-chrome)
* LibreChat: [https://github.com/danny-avila/LibreChat](https://github.com/danny-avila/LibreChat)

---

## Building a Docker image

> The repo includes a `Dockerfile` for the orchestrator and a `docker-compose.yml` that wires everything.

```bash
# Build orchestrator alone
docker build -t voygent/orchestrator ./orchestrator

# Run with compose (recommended)
docker compose up -d --build
```

For production:

* Put Caddy/NGINX in front (TLS, gzip, caching).
* Use Neon Postgres for durability.
* Mount `data/` for persistent storage and assets.

---

Features (Phase 1 – CE)

AI‑assisted itineraries: From lead intake to trip concepts to final proposal.

Beautiful proposals: Render HTML → PDF with modern templates.

Self‑hosted dashboard: Manage clients, trips, and proposals.

Bring Your Own AI Key: Works with Claude, GPT, Gemini, etc.

Local browser integration: Use mcp‑chrome (or Opera Neon when available) for live extraction from booking sites.

Open database schema: Hybrid normalized + LLM‑friendly tables.

Architecture Overview

LibreChat inside Docker – orchestrator + UI.

Cloudflare D1 (default) or Postgres/Neon – trip & proposal data.

Nunjucks/Handlebars templates – render HTML proposals.

Caddy reverse proxy with HTTPS.

MCP servers:

mcp-chrome (local install, outside Docker)

Cloudflare Workers MCP (prompt-instructions)

Other MCPs as needed (e.g. HTML ingestion, custom APIs)

❗ mcp‑chrome should run separately on the user’s local machine for browser integration. Running it in Docker is possible but brittle.

### Screenshots (placeholders)

* docs/screenshots/dashboard.png – Dashboard view

* docs/screenshots/proposal.png – Proposal render

* docs/screenshots/install.png – Install steps

## Troubleshooting

* **Proxy complains about \${LIBRECHAT\_HOST}**: ensure your `.env` is loaded by compose and values appear in `docker compose config`.
* **LibreChat boots but no tools**: check `ALLOWED_MCP_ORIGINS` and your MCP tool registration in LibreChat.
* **No data in `trip_facts`**: you must POST `/api/facts/refresh/:tripId` after ingesting hotels/rooms.
* **PDF export fails**: install Chromium and ensure Puppeteer has access, or disable PDF in render calls.

---

## Roadmap (CE)

* Hosted runners (replace local browser automation)
* More vendor normalizers (rooms/amenities without extra clicks)
* Template gallery & theme variables
* Ad‑hoc SQL admin with safe templates

---

## License

* Community Edition licensed under an OSI‑approved license (e.g., AGPL‑3.0 or Apache‑2.0). Choose what aligns with your goals.

---

## Contributing

PRs welcome! Focus areas:

* Vendor extractors → normalized `HotelOption[]`
* Proposal templates (Nunjucks)
* Query intents & filters
* Docs & examples
