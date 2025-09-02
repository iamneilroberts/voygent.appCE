# Repository Guidelines

## Project Structure & Module Organization
- `orchestrator/`: Node.js Express API (`server.js`, `package.json`).
- `scripts/`: Shell helpers to set up and run services (`setup.sh`, `start-services.sh`).
- `config/`, `db/`, `templates/`: App config, SQL schema (`db/d1.sql`), Nunjucks proposal templates.
- `data/`: Runtime data (SQLite, logs, uploads). Do not commit.
- `docs/`: Platform guides (MCP config, Windows install).
- `mcp-chrome/`: Local browser automation workspace (separate Node project).

## Build, Test, and Development Commands
```bash
# One‑time setup (creates .env, validates tools)
./scripts/setup.sh

# Start services (LibreChat, DBs, local orchestrator if in local/hybrid mode)
./scripts/start-services.sh

# Docker basics
docker-compose up -d --build
docker-compose logs -f
docker-compose down

# Orchestrator local dev
cd orchestrator && npm install && npm run dev
# Orchestrator tests (Node test runner)
cd orchestrator && npm test
```

## Coding Style & Naming Conventions
- JavaScript: ES modules, 2‑space indent, semicolons, single quotes.
- Files: `lowercase-with-dashes` for dirs; `camelCase` for JS helpers; `PascalCase` for classes.
- Templates: Nunjucks in `templates/`, keep logic minimal; prefer small, reusable partials.
- Shell: POSIX‑compatible; keep scripts idempotent and non‑interactive unless documented.

## Testing Guidelines
- Framework: Node’s built‑in test runner (`npm test`). Place tests in `orchestrator/test/` as `*.test.js`.
- Cover happy paths and error handling for routes, DB access, and utilities.
- For Docker changes, include a brief manual check plan (health endpoints, ports 3000/3080).

## Commit & Pull Request Guidelines
- Commits: Imperative mood, scope first line to area (e.g., `orchestrator:`). Example: `orchestrator: add /health route and DB init guard`.
- PRs: Include purpose, screenshots/logs when UX/API changes, reproduction/verification steps, and any env or schema updates.
- Link related issues. Keep PRs focused and small when possible.

## Security & Configuration Tips
- Never commit secrets. Use `.env` (see `.env.example`).
- Modes: Local/Remote/Hybrid controlled via `MCP_MODE` and component flags; verify CORS via `ALLOWED_WEB_ORIGINS`.
- Exposed ports: LibreChat `3080`, Orchestrator `3000`. Validate with `/health` before merging infra changes.

