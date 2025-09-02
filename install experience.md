End-to-end install experience (new computer, any OS)

Goal: “clone → edit .env → docker compose up → open browser → start planning”.
mcp-chrome remains a separate install the user runs locally.

What the user does

Install Docker Desktop (Mac/Windows) or Docker engine (Linux).

Clone your voygent-ce repo and copy .env.example → .env.

docker compose up -d (spins up Orchestrator, LibreChat, DB, Proxy).

Install mcp-chrome from GitHub (host OS), run it on port (e.g., 5173).

Visit http://localhost:3080 (or https://chat.voygent.app on a VPS) and start the assistant.

Nice-to-have: a tiny bootstrap script: