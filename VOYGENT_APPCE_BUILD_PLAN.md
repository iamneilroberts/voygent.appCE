# Voygent.appCE Repository Build Plan

Based on my analysis of the current voygen system and the voygenCE structure, here's a comprehensive plan to build the complete voygent.appCE repository that allows full system installation on a new computer.

## Phase 1: Core Repository Structure
- **Create base directory structure** matching the CE architecture:
  - `orchestrator/` - Express API server for hotel ingestion, facts management, and proposal rendering
  - `db/` - Database schema and migration files (SQLite/D1/Postgres compatible) 
  - `templates/` - Nunjucks templates for proposal rendering
  - `data/` - Directory for SQLite files and assets
  - `docker/` - Docker configurations and compose files
  - `docs/` - Installation guides, API documentation, screenshots
  - `scripts/` - Setup, deployment, and utility scripts

## Phase 2: Migration of Core Components
- **Port essential MCP servers** from the current voygen system:
  - mcp-chrome (local browser automation) - copy as-is for local installation
  - Simplified database layer compatible with CE schema
  - Basic prompt-instructions functionality for workflow management
  - Template rendering engine for proposals

- **Convert LibreChat configuration** to CE format:
  - Simplified librechat.yaml with MCP server definitions
  - Environment variable configurations
  - Remove complex Cloudflare Workers dependencies for core functionality

## Phase 3: New CE-Specific Components  
- **Build the Orchestrator API server** (`orchestrator/server.js`):
  - Express server with SQLite/Postgres support
  - Core endpoints: `/api/ingest/hotels`, `/api/facts/refresh`, `/api/plan/city`, `/api/proposal/render`
  - Normalized hotel data ingestion from mcp-chrome automation
  - Facts management and L/M/H hotel recommendation logic
  - Template rendering with Nunjucks for HTML/PDF proposals

- **Create database schema** (`db/d1.sql`):
  - trips, trip_legs, trip_facts, ingested_hotels tables
  - Hybrid normalized + JSON structure for LLM optimization
  - Compatible with SQLite (default), D1, and Postgres

- **Docker containerization**:
  - Multi-service docker-compose.yml (orchestrator, librechat, postgres, caddy proxy)  
  - Production-ready Dockerfile for orchestrator
  - Caddy reverse proxy configuration with HTTPS
  - Volume mounts for persistent data

## Phase 4: Installation & Configuration System
- **Comprehensive setup scripts**:
  - One-command Docker Compose setup for quick local deployment
  - Manual installation scripts for those preferring local Node.js setup
  - Environment configuration templates (.env.example)
  - Database initialization and migration scripts

- **Configuration management**:
  - Environment-specific configs (dev/staging/prod)
  - API key management (BYOK - Bring Your Own Keys)
  - CORS and security configurations
  - LibreChat + MCP server integration settings

## Phase 5: Documentation & Templates
- **Complete documentation system**:
  - README with quickstart (Docker Compose in 3 commands)
  - API endpoint documentation with curl examples
  - Architecture overview diagrams
  - Troubleshooting guides and common issues
  - Manual installation guide for non-Docker deployments

- **Proposal templates**:
  - Professional Nunjucks templates for HTML proposals
  - CSS styling for print-ready PDF generation
  - Template variables for customization
  - Example data for testing rendering

## Phase 6: Testing & Validation
- **End-to-end test suite**:
  - API endpoint testing (hotel ingestion → facts → recommendations)  
  - Template rendering validation
  - Docker Compose deployment testing
  - Database migration testing across SQLite/Postgres

- **Example data and workflows**:
  - Sample trip data for testing
  - Example hotel ingestion curl commands
  - Complete workflow examples (lead → proposal)

## Key Differences from Current Voygen
1. **Self-contained**: No external Cloudflare Workers dependencies for core functionality
2. **BYOK Model**: Users provide their own LLM API keys instead of shared infrastructure
3. **Simplified deployment**: Docker Compose for easy local/VPS deployment
4. **Local browser automation**: mcp-chrome runs on user's machine, not in Docker
5. **Flexible database**: Supports SQLite (default), D1, or Postgres based on needs
6. **Template-based**: Nunjucks templates for customizable proposal generation

## Installation Flow for New Users
1. `git clone https://github.com/iamneilroberts/voygent.appCE.git`
2. `cd voygent-ce && cp .env.example .env` (edit with API keys)
3. `docker compose up -d --build` 
4. Install mcp-chrome locally for browser automation
5. Access LibreChat UI at localhost:3080
6. Start planning trips with AI assistance!

## Components That Must Be Included in voygent.appCE Repository

### From Current Voygen System:
- `mcp-local-servers/mcp-chrome/` - Complete browser automation system
- `config/librechat-minimal.yaml` - LibreChat configuration (adapted for CE)
- `.env.example` - Environment configuration template
- `scripts/setup.sh` - Setup automation (adapted for CE)

### New CE-Specific Components:
- `orchestrator/server.js` - Main API server
- `orchestrator/package.json` - Dependencies
- `orchestrator/Dockerfile` - Container definition
- `db/d1.sql` - Database schema
- `templates/proposal.njk` - Proposal template
- `docker-compose.yml` - Multi-service orchestration
- `Caddyfile` - Reverse proxy configuration
- `README.md` - Installation and usage guide
- `docs/api.md` - API documentation
- `docs/architecture.md` - System overview
- `scripts/init-db.sh` - Database initialization

### Testing and Examples:
- `examples/sample-trip.json` - Example data
- `examples/curl-commands.sh` - API testing examples
- `tests/` - Automated test suite

This plan creates a complete, self-hosted travel planning system that maintains the core Voygen functionality while being installable and runnable entirely on a new computer without external service dependencies.