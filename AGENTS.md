# Repository Guidelines

## Project Structure & Module Organization
- orchestrator: Node.js Express API (`orchestrator/server.js`), ESM modules. Persists to SQLite by default (`data/`), schema in `db/d1.sql`, proposal templates in `templates/`.
- mcp-chrome: MCP browser automation (pnpm monorepo). LibreChat spawns `mcp-chrome/app/native-server/dist/index.js` in the container.
- tray: Simple Electron tray controller (`tray/`).
- config: LibreChat config (`config/librechat.yaml`).
- scripts: Setup and helpers (`scripts/setup.sh`, `scripts/start-services.sh`, OS-specific tools).
- Docker: `docker-compose.yml` services and `Caddyfile` proxy; persistent data under `data/`.

## Build, Test, and Development Commands
- First run: `./scripts/setup.sh` then `./voygent start` (or `voygent.bat` on Windows).
- Compose dev: `docker compose up -d --build` and `docker compose logs -f`.
- Orchestrator dev: `cd orchestrator && npm i && npm run dev` (watch) or `npm start`.
- MCP Chrome: `pnpm --dir mcp-chrome install && pnpm --dir mcp-chrome build`.
- Tray: `pnpm --dir tray dev` (optional UI controller).
- Health check: `curl -s http://localhost:3000/health`.

## Coding Style & Naming Conventions
- JS/Node (ESM): 2-space indent, semicolons, async/await, small handlers with clear JSON shapes (`{ ok, error, ... }`).
- Filenames: kebab-case for scripts; config in `.env` (copy from `.env.example`).
- Lint/format: mcp-chrome uses ESLint + Prettier; keep consistent there. For orchestrator, match existing style in `server.js`.

## Testing Guidelines
- Framework: Node’s built-in test runner (`npm test` in `orchestrator`, looks for `test/*.js`). If adding tests, place under `orchestrator/test/`.
- Coverage: Add at least one happy-path test per new endpoint; prefer endpoint-level tests with fixtures.
- Smoke examples: `curl` POST `/api/ingest/hotels`, then POST `/api/facts/refresh/:tripId`, then POST `/api/facts/query` to verify flow.

## Commit & Pull Request Guidelines
- Commits: Conventional style preferred (e.g., `feat(orchestrator): add facts query`, `fix(proxy): correct Caddy health route`, `chore(scripts): improve setup prompts`).
- PRs: Include description, linked issues, run/test notes, and screenshots or logs (LibreChat UI and `/health` output) when relevant.
- Do not include `.env` or secrets; ensure new env keys are documented in `.env.example`.

## Security & Configuration Tips
- BYOK: Keep provider keys in `.env` only; never commit secrets.
- Origins: Restrict `ALLOWED_WEB_ORIGINS` and `ALLOWED_MCP_ORIGINS` for local vs. prod.
- Logging: Avoid logging full payloads with credentials; sanitize request bodies.
