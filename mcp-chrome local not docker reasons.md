Should mcp-chrome run inside Docker?

Short answer: Don’t.
Why: mcp-chrome controls / talks to a real, user-signed-in browser profile. Putting it in a container complicates user profiles, keychain/OS prompts, accessibility/DevTools handshakes, and cross-OS networking. You’ll spend time fighting host/container boundaries.

Recommendation:

Run mcp-chrome on the host OS (Linux/Mac/Windows), not in the container.

Run LibreChat + Orchestrator + DB in Docker.

Connect LibreChat (in the container) → mcp-chrome (on the host) using one of the OS-specific network tricks below.

How to wire it up (works today)

Linux: In docker-compose.yml put LibreChat on host network so it can reach ws://127.0.0.1:<MCP_PORT>.