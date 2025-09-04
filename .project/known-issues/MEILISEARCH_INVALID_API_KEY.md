# MeiliSearch invalid API key errors

- Symptom: Repeated `MeiliSearchApiError: The provided API key is invalid.` in `data/logs/*meili*`.
- Context: docker-compose enables `meilisearch`; README notes previously mentioned temporary disable. Keys may not match.
- Paths: `data/meilisearch/`, `data/logs/meiliSync-*.log`.
- Next steps:
  1) Verify `MEILI_MASTER_KEY` in `.env` matches compose and LibreChat config.
  2) Decide whether MeiliSearch is enabled by default; update docs accordingly.
  3) Clear dev data if needed: stop services, remove `data/meilisearch/`, restart.
  4) Track in TASK-2025-208.
