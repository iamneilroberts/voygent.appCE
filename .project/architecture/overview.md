# Architecture Overview (brief)

- UI: LibreChat container, MCP-enabled.
- Orchestrator: Express API (`/api/ingest/*`, `/api/facts/*`, `/api/plan/city`, `/api/proposal/render`), SQLite by default.
- Automation: `mcp-chrome` runs locally; LibreChat spawns it in-container via bind mount.
- Data: `data/` for SQLite, uploads, logs; schema in `db/d1.sql`.
- Proxy: Caddy (optional profile) for unified routing.

References: README.md and VOYGENT_APPCE_BUILD_PLAN.md.
