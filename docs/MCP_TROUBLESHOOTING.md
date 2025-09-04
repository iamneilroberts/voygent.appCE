# MCP Troubleshooting Guide

## Common Issues and Solutions

### Issue: MCPManager Not Initializing

**Symptoms:**
- Error logs showing: `Error loading MCP servers MCPManager has not been initialized`
- Error logs showing: `[getAvailableTools] MCPManager has not been initialized`
- MCP tools not appearing in LibreChat interface
- Custom endpoints (Voygent Anthropic/OpenAI) visible but MCP servers not working

**Root Cause:**
LibreChat requires MCP servers to be defined globally at the top level of the configuration file, not just within individual endpoints.

**Solution:**
Add a global `mcpServers` section at the top of your `librechat.yaml` file:

```yaml
version: 1.1.0
cache: true

# REQUIRED: Global MCP server definitions for initialization
mcpServers:
  d1_database:
    type: "streamable-http"
    url: "https://d1-database-improved.somotravel.workers.dev/sse"
    description: "Advanced trip and hotel data management (Remote Mode)"
  prompt_instructions:
    type: "streamable-http"
    url: "https://prompt-instructions-d1-mcp.somotravel.workers.dev/sse"
    description: "Workflow and conversation management (Remote Mode)"

endpoints:
  custom:
    # ... your endpoint configurations
```

**Verification:**
After adding the global section and restarting LibreChat, you should see:
```
[MCP][prompt_instructions] Creating streamable-http transport: https://...
[MCP][d1_database] Creating streamable-http transport: https://...
MCP servers initialized successfully. Added 44 MCP tools.
```

### Issue: Environment Variables Not Substituted

**Symptoms:**
- MCP URLs showing as `${MCP_D1_DATABASE_SSE_URL}` in logs
- MCP servers failing to connect

**Solution:**
LibreChat doesn't automatically substitute environment variables in YAML. Use actual URLs directly in the configuration file.

### Issue: Invalid Configuration File

**Symptoms:**
- Error: `Unrecognized key(s) in object: 'plugins'`
- Configuration validation errors

**Solution:**
Remove any invalid keys like `plugins` from the configuration. LibreChat v0.8.0-rc3 doesn't support a plugins section.

## Successful MCP Initialization Logs

When MCP is working correctly, you should see:
1. Transport creation messages for each MCP server
2. Server capabilities and tools listed
3. Final success message with total tool count

Example:
```
[MCP][prompt_instructions] Creating streamable-http transport
[MCP][prompt_instructions] Tools: get_instruction, list_instructions, ...
[MCP][d1_database] Creating streamable-http transport
[MCP][d1_database] Tools: health_check, update_activitylog_clients, ...
MCP servers initialized successfully. Added 44 MCP tools.
```

## Configuration Structure

The correct structure requires:
1. Global `mcpServers` definition (for initialization)
2. Endpoint-specific `mcpServers` definition (for endpoint association)

Both are needed for full functionality.