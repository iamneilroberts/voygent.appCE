# VoygentCE MCP Server Configuration Guide

## Overview

VoygentCE supports flexible MCP (Model Context Protocol) server configuration, allowing you to choose between fully local operation or connecting to existing Cloudflare Workers infrastructure. This guide explains all configuration options and use cases.

## Configuration Modes

### 1. Local Mode (Default)
**Best for**: Privacy-focused users, offline work, complete control

```bash
MCP_MODE=local
MCP_DATABASE_MODE=local
MCP_INSTRUCTIONS_MODE=local
```

**Features**:
- ✅ Fully self-contained - no external dependencies
- ✅ Complete data ownership and privacy
- ✅ Fastest response times (no network latency)
- ✅ Works offline after initial setup
- ✅ BYOK cost model with full control
- ✅ SQLite or PostgreSQL database options
- ❌ Requires local database management
- ❌ No shared data across installations

### 2. Remote Mode
**Best for**: Users with existing Voygen Cloudflare infrastructure

```bash
MCP_MODE=remote
MCP_DATABASE_MODE=remote
MCP_INSTRUCTIONS_MODE=remote

# Required remote URLs
MCP_D1_DATABASE_URL=https://d1-database-improved.somotravel.workers.dev
MCP_D1_DATABASE_SSE_URL=https://d1-database-improved.somotravel.workers.dev/sse
MCP_PROMPT_INSTRUCTIONS_URL=https://prompt-instructions-d1-mcp.somotravel.workers.dev
MCP_PROMPT_INSTRUCTIONS_SSE_URL=https://prompt-instructions-d1-mcp.somotravel.workers.dev/sse
MCP_AUTH_KEY=your-secret-auth-key
```

**Features**:
- ✅ Leverage existing Cloudflare infrastructure
- ✅ Shared data across multiple installations
- ✅ Automatic backups and scaling via Cloudflare
- ✅ No local database maintenance required
- ✅ Advanced features from production MCP servers
- ✅ Commission optimization and fact materialization
- ❌ Requires network connectivity
- ❌ Data stored on external servers
- ❌ Potential network latency

### 3. Hybrid Mode
**Best for**: Advanced users wanting custom setups

```bash
MCP_MODE=hybrid
# Individual component configuration
MCP_DATABASE_MODE=local        # or remote
MCP_INSTRUCTIONS_MODE=remote   # or local
```

**Common Hybrid Configurations**:

#### Option A: Local Data, Remote Workflows
```bash
MCP_DATABASE_MODE=local
MCP_INSTRUCTIONS_MODE=remote
```
- Keep sensitive trip/client data local
- Use remote workflow management and instructions
- Best for: Privacy + advanced workflow features

#### Option B: Remote Data, Local Workflows  
```bash
MCP_DATABASE_MODE=remote
MCP_INSTRUCTIONS_MODE=local
```
- Share data across installations
- Keep workflow logic local
- Best for: Multi-user setups with local control

## Component Details

### Browser Automation (mcp-chrome)
**Always Local** - Runs on your machine for security and functionality

- **Path**: `./mcp-chrome/dist/index.js` (configurable via `MCP_CHROME_PATH`)
- **Purpose**: Real-time hotel data extraction from booking sites
- **Requirements**: Chrome/Chromium installed locally
- **Tools**: screenshot, click_element, type_text, extract_hotels, navigate_to_url

### Database Services

#### Local Database (orchestrator)
- **Service**: Local Express.js API server
- **Database**: SQLite (default) or PostgreSQL
- **Port**: 3000
- **Tools**: create_trip, ingest_hotels, ingest_rooms, refresh_facts, query_facts, plan_city, render_proposal

#### Remote Database (d1-database)
- **Service**: Cloudflare Workers with D1 database
- **Transport**: Server-Sent Events (SSE)
- **Tools**: get_anything, create_trip_with_client, ingest_hotels, query_hotels, query_trip_facts, optimize_commission, bulk_trip_operations

### Workflow Instructions

#### Local Instructions
- **Implementation**: Basic workflow logic in orchestrator
- **Features**: Simple trip planning workflows

#### Remote Instructions (prompt-instructions)  
- **Service**: Cloudflare Workers with advanced workflow management
- **Transport**: Server-Sent Events (SSE)
- **Tools**: travel_agent_start, continue_trip, get_instruction
- **Features**: Dynamic workflow phases, conversation state management

## Setup Process

### Interactive Setup
Run the setup script for guided configuration:
```bash
./scripts/setup.sh
```

This will:
1. Prompt for MCP mode selection
2. Configure environment variables
3. Set up API keys
4. Install dependencies
5. Start appropriate services

### Manual Configuration

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Configure MCP mode in `.env`**:
   ```bash
   # Choose your mode
   MCP_MODE=local|remote|hybrid
   
   # For hybrid mode, configure individual components
   MCP_DATABASE_MODE=local|remote
   MCP_INSTRUCTIONS_MODE=local|remote
   ```

3. **Add remote URLs if needed**:
   ```bash
   MCP_D1_DATABASE_URL=https://your-d1-worker.workers.dev
   MCP_D1_DATABASE_SSE_URL=https://your-d1-worker.workers.dev/sse
   MCP_PROMPT_INSTRUCTIONS_URL=https://your-instructions-worker.workers.dev
   MCP_PROMPT_INSTRUCTIONS_SSE_URL=https://your-instructions-worker.workers.dev/sse
   MCP_AUTH_KEY=your-auth-key
   ```

4. **Generate LibreChat configuration**:
   ```bash
   ./scripts/configure-librechat.sh
   ```

5. **Start services**:
   ```bash
   ./scripts/start-services.sh
   ```

## Service Architecture

### Local Mode Architecture
```
[LibreChat] → [Local Orchestrator] → [SQLite/PostgreSQL]
     ↓
[mcp-chrome] (local browser automation)
```

### Remote Mode Architecture  
```
[LibreChat] → [Remote MCP Servers] → [Cloudflare D1]
     ↓
[mcp-chrome] (local browser automation)
```

### Hybrid Mode Architecture
```
[LibreChat] → [Local Orchestrator] → [SQLite/PostgreSQL]
     ↓            ↓
[mcp-chrome] → [Remote Instructions] → [Cloudflare KV]
```

## Docker Compose Profiles

The system uses Docker Compose profiles to start appropriate services:

- **Default**: LibreChat, MongoDB, MeiliSearch (always running)
- **local-database**: Adds Orchestrator service (local/hybrid database mode)
- **proxy**: Adds Caddy reverse proxy (optional)

Services are automatically selected based on MCP configuration.

## API Compatibility

The orchestrator service maintains API compatibility regardless of mode:

### Local Mode
- Direct SQLite/PostgreSQL database queries
- Local business logic processing
- Fast response times

### Remote Mode  
- Proxies requests to Cloudflare Workers MCP servers
- Transparent API compatibility
- Advanced features like commission optimization

### Common Endpoints
- `GET /health` - Service health check
- `GET /api/trips` - List all trips
- `POST /api/trips` - Create new trip
- `POST /api/ingest/hotels` - Store hotel data
- `POST /api/facts/refresh/:tripId` - Update trip facts
- `POST /api/facts/query` - Query trip data
- `POST /api/plan/city` - Get L/M/H recommendations
- `POST /api/proposal/render` - Generate proposals

## Troubleshooting

### Common Issues

#### Remote Server Not Reachable
```bash
❌ Cannot reach D1 database server
```
**Solutions**:
- Check `MCP_D1_DATABASE_URL` in `.env`
- Verify Cloudflare Workers are deployed
- Test connectivity: `curl https://your-worker.workers.dev/health`
- Check authentication: verify `MCP_AUTH_KEY`

#### LibreChat Configuration Issues
```bash
❌ LibreChat tools not available
```
**Solutions**:
- Regenerate config: `./scripts/configure-librechat.sh`
- Check `config/librechat.yaml` was generated correctly
- Restart LibreChat: `docker-compose restart librechat`

#### Service Profile Issues
```bash
❌ Orchestrator not starting in remote mode
```
**Solutions**:
- This is expected - orchestrator only runs in local/hybrid mode
- Check Docker profiles: `docker-compose ps`
- Verify environment variables: `echo $MCP_DATABASE_MODE`

### Debug Commands

```bash
# Check running services
docker-compose ps

# View service logs
docker-compose logs -f librechat
docker-compose logs -f orchestrator

# Test API endpoints
curl http://localhost:3080  # LibreChat
curl http://localhost:3000/health  # Orchestrator (if running)

# Regenerate configuration
./scripts/configure-librechat.sh

# Restart with new configuration
docker-compose restart
```

### Validation Scripts

```bash
# Test complete system
./scripts/test-setup.sh

# Validate MCP configuration
./scripts/configure-librechat.sh

# Check service health
curl -s http://localhost:3000/health | jq
```

## Migration Between Modes

### From Local to Remote
1. Deploy Cloudflare Workers with your data
2. Update `.env` with remote URLs
3. Change `MCP_MODE=remote`
4. Restart: `./scripts/start-services.sh`

### From Remote to Local
1. Backup remote data (if needed)
2. Update `.env` with `MCP_MODE=local`  
3. Restart: `./scripts/start-services.sh`
4. Import data to local database (if needed)

### Local ↔ Hybrid
- Update individual component modes in `.env`
- Restart services: `./scripts/start-services.sh`

## Best Practices

### Security
- Use strong `MCP_AUTH_KEY` for remote servers
- Keep API keys secure in `.env` (never commit)
- Use HTTPS for all remote endpoints
- Restrict Cloudflare Worker access as needed

### Performance  
- Local mode: Fastest for single-user setups
- Remote mode: Better for multi-user, high-availability needs
- Hybrid mode: Optimize based on your specific requirements

### Data Management
- Local mode: Regular backups of SQLite database
- Remote mode: Rely on Cloudflare's built-in backup/replication
- Hybrid mode: Backup local components, monitor remote connectivity

### Cost Optimization
- Local mode: Only pay for LLM API usage
- Remote mode: Add Cloudflare Workers compute costs
- Hybrid mode: Mix based on usage patterns

This configuration system gives you complete flexibility to run VoygentCE exactly how you need it, from fully local to fully remote or any combination in between.