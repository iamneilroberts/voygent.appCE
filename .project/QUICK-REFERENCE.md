# Quick Reference

Common commands
- Setup: `./scripts/setup.sh`
- Start/Stop: `./voygent start|stop|restart|status|logs`
- Docker: `docker compose up -d --build`, `docker compose logs -f`
- Orchestrator dev: `cd orchestrator && npm i && npm run dev`
- Tray dev: `pnpm --dir tray dev`

Checks
- Health: `curl -s http://localhost:3000/health | jq`
- LibreChat: open http://localhost:3080

Paths
- Data: `data/` (db, uploads, logs)
- Config: `.env`, `config/librechat.yaml`
- API schema: `db/d1.sql`
