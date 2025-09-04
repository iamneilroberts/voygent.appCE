# TASK-2025-206 Remove inline provider keys from config/librechat.yaml

- Status: completed
- Area: security, config
- Summary: Eliminated hardcoded Anthropic/OpenAI keys in `config/librechat.yaml`; now sourced from environment.
- Implementation:
  - Replaced literal keys with `${ANTHROPIC_API_KEY}` and `${OPENAI_API_KEY}`.
  - Confirmed `.env.example` already contains placeholders for both keys.
  - Start-up script `scripts/start-services.sh` invokes `scripts/configure-librechat.sh` to render from template cross-platform.
- Validation:
  - Keys no longer appear in the repo.
  - LibreChat authenticates when `.env` provides keys; works on Linux and Windows via `voygent.bat`.
