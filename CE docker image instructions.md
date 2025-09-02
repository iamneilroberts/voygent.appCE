Perfect—here’s a **copy-paste prompt** you can drop into a fresh chat window to get a **step-by-step to-do** for bringing up **Voygent CE** as Docker services, wired to **Cloudflare D1 (via MCP)** + **Cloudflare Worker prompts MCP**, with **HTML templates** stored locally or in D1. It tells the LLM exactly what to output (commands, files, env, OS notes, troubleshooting) so you can follow along on a clean machine.

---

# 👇 Paste everything below into a new chat

You are an expert DevOps + full-stack guide. I’m standing up **Voygent CE** (self-hosted, BYOK) on a fresh machine using **Docker**. Generate an **actionable, copy-paste step-by-step** that gets me from zero → running **Voygent CE** with:

* **LibreChat** (chat UI) in Docker
* **Orchestrator** (Express/Node) in Docker
* **Reverse proxy** (Caddy or Nginx) in Docker
* **Database:** use **Cloudflare D1 via an MCP server** (not a direct DB connection)
* **Prompts MCP:** a **Cloudflare Worker** that serves “prompt-instructions” for the travel workflow
* **mcp-chrome:** runs **on the host OS**, not in Docker (Chrome automation)
* **Templates:** stored **locally** in `templates/` by default, and optionally **in D1** (accessed via MCP)
* **Name/Domain:** brand is **Voygent**, domain **voygent.app** (but allow `localhost` setup first)

I already have a **Community Edition repo skeleton** similar to this (assume I can clone it):

* `docker-compose.yml`
* `orchestrator/` (server.js, package.json, Dockerfile)
* `db/d1.sql` (schema used to seed template content if desired)
* `templates/proposal.njk`
* `.env.example`
* `Caddyfile`
* CI workflow to build the orchestrator image (optional)

> Important: mcp-chrome must remain a separate host install and be reachable from Dockerized LibreChat/Orchestrator (see OS-specific networking below).

## What I want you to produce

### A) Clear prerequisites

* Docker engine & Docker Desktop (Mac/Win) or engine (Linux), Git, Node (if needed), Cloudflare account + Wrangler
* Cloudflare Worker setup (namespaces/bindings if needed)
* Cloudflare D1 database creation (for MCP server to talk to)

### B) Environment & topology

* Diagram (text) of services and ports:

  * `librechat` (e.g., 3080), `orchestrator` (3000), `reverse proxy` (80/443)
  * `mcp-chrome` (host OS, e.g., 5173 WebSocket)
  * Cloudflare Worker (Prompts MCP, HTTPS URL)
  * D1 MCP (WebSocket/HTTP endpoint) and how LibreChat will reference it
* Explain **why mcp-chrome is outside Docker** and how Docker reaches it:

  * **Linux:** `network_mode: host` or expose host port
  * **macOS/Windows:** `host.docker.internal` for MCP WS URL

### C) Files to create/verify (inline code blocks)

Provide final, copy-paste-ready content for:

1. **`.env` (root)** — Fill with placeholders and comments:

   * `LIBRECHAT_HOST`, `API_HOST`, `PORT`, `ALLOWED_WEB_ORIGINS`, `ALLOWED_MCP_ORIGINS`
   * LLM keys: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`
   * Optional: `DATABASE_URL` if I later switch to Postgres
   * Worker/MCP endpoints: `PROMPTS_MCP_URL`, `D1_MCP_URL`
   * For local dev, show minimal viable values (localhost)

2. **`docker-compose.yml`** — Include services:

   * `orchestrator` (build from `./orchestrator`, mounts `./data` & `./templates`)
   * `librechat` (image), environment for MCP tool registration
   * `proxy` (Caddy with mounted `Caddyfile`)
   * Optional lightweight SQLite container for dev if I don’t use D1
   * Correct networks, depends\_on, and healthchecks
   * OS-notes: Linux host networking vs `host.docker.internal` for Mac/Win

3. **`Caddyfile`** — Local and production examples:

   * Local: terminate TLS off, proxy to `librechat:3080` and `orchestrator:3000`
   * Production: `voygent.app` + optional `chat.voygent.app` + automatic TLS

4. **`orchestrator/server.js`** — Minimal API with endpoints:

   * `/health`, `/api/ingest/hotels`, `/api/ingest/rooms`, `/api/facts/refresh`, `/api/proposal/render`
   * Reads templates from `./templates/` by default; if `USE_D1_TEMPLATES=true`, fetch template via **D1 MCP** tool (show stub call)
   * Simple Nunjucks render to HTML; optional PDF via Puppeteer (comment it but keep it off by default)

5. **LibreChat MCP tool config** (JSON or YAML block):

   * Register **mcp-chrome**: `ws://host.docker.internal:5173` (Mac/Win) or `ws://127.0.0.1:5173` with host networking (Linux)
   * Register **Prompts MCP (Cloudflare Worker)**: `https://<your-worker>.<subdomain>.workers.dev`
   * Register **D1 MCP**: `wss://...` or `https://...` per your MCP server (assume a Worker as well)
   * Show where this config lives (env var vs file path) for LibreChat

6. **`db/d1.sql`** — Confirm tables:

   * `trips`, `trip_legs`, `trip_facts`, `ingested_hotels`, plus **activities**, **transport**, **financials** (basic versions)
   * If templates in D1: a `templates` table with `name`, `html`, `updated_at`

7. **Cloudflare Worker: Prompts MCP** — Minimal Worker code snippet:

   * GET `/phase/:id` returns instruction fragments
   * Example phases: `intake`, `concepts`, `plan_city`, `shortlist_hotels`, `render_proposal`, `commissions`, `validate`
   * Show `wrangler.toml` with a route and deploy command

8. **Cloudflare Worker: D1 MCP** — Minimal Worker code snippet:

   * Expose MCP `readTemplate(name)` or generic SQL query with allow-list
   * Bind D1 database in `wrangler.toml`
   * Show `wrangler d1 execute` to seed from `db/d1.sql` if storing templates

### D) Commands (copy-paste)

* `git clone … && cd voygent-ce && cp .env.example .env && nano .env`
* `docker compose up -d --build`
* Cloudflare:

  * `wrangler login`
  * `wrangler d1 create voygent_ce`
  * `wrangler d1 execute voygent_ce --file db/d1.sql`
  * `wrangler deploy` (Prompts MCP & D1 MCP Workers)
* **mcp-chrome** on host:

  * Install & run, e.g., `npm i -g mcp-chrome && mcp-chrome --port 5173`
* Health checks:

  * `curl http://localhost:3000/health`
  * open `http://localhost:3080` (LibreChat)

### E) OS-specific networking

* **Linux:**

  * Use `network_mode: host` for LibreChat so `ws://127.0.0.1:5173` works
* **macOS/Windows (Docker Desktop):**

  * Use `host.docker.internal` in LibreChat MCP config to reach the host’s mcp-chrome

### F) First-run flow (smoke test)

1. Start stack → visit LibreChat
2. Send `/new "Smith Vancouver May 2026, 7 nights, PE flights, boutique walkable"`
3. Confirm it calls **Prompts MCP** for phase text
4. Add mock hotel/room data with `POST /api/ingest/hotels` & `/api/ingest/rooms`
5. Run `/commissions` (deterministic demo numbers are fine)
6. Run `/validate` (show that hours/season logic executes)
7. `/render` → returns HTML using `templates/proposal.njk`
8. (Optional) enable PDF and save to `data/proposals/…pdf`

### G) Troubleshooting section

* Common Caddy errors (domain, env vars)
* LibreChat cannot reach MCPs (how to verify URLs from inside the container)
* mcp-chrome handshake (port in use, browser profile issues)
* Cloudflare Worker 403/404 (routes/bindings), D1 query limits
* SELinux/macOS permissions for mounted volumes

### H) Security & production notes

* HTTPS in production via Caddy; env secrets; rate-limits for API; auth for admin endpoints
* Image tags and GHCR pulls; backups for templates & trip data

### I) Output format

Produce the guide with **clearly labeled sections**, each containing:

* Short explanation (1–3 sentences)
* **Exact files** (inline code)
* **Exact commands** (bash and PowerShell where it matters)
* A final **TL;DR checklist** and **Rollback steps** (stop/remove containers, clear volumes, redeploy)

Use `<PLACEHOLDER>` for items I must customize: domains, Worker URLs, keys. Keep everything **copy-paste-ready**.

---

That’s it. Please generate the full guide now.
