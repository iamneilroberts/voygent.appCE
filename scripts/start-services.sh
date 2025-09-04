#!/bin/bash
# VoygentCE Service Startup Script
# Starts appropriate Docker services based on MCP mode

set -e

# Choose docker compose command
compose() {
    if docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

echo "🚀 Starting VoygentCE Services..."

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set defaults
MCP_MODE=${MCP_MODE:-local}
MCP_DATABASE_MODE=${MCP_DATABASE_MODE:-local}
MCP_INSTRUCTIONS_MODE=${MCP_INSTRUCTIONS_MODE:-local}

echo "📋 Configuration:"
echo "   MCP Mode: $MCP_MODE"
echo "   Database Mode: $MCP_DATABASE_MODE" 
echo "   Instructions Mode: $MCP_INSTRUCTIONS_MODE"

# Generate LibreChat configuration
echo "🔧 Generating LibreChat configuration..."
./scripts/configure-librechat.sh

# Determine Docker Compose profiles based on mode
COMPOSE_PROFILES=""

# Always include core services
COMPOSE_PROFILES="$COMPOSE_PROFILES"

# Add orchestrator if using local database mode
if [ "$MCP_DATABASE_MODE" = "local" ] || [ "$MCP_MODE" = "local" ] || [ "$MCP_MODE" = "hybrid" ]; then
    COMPOSE_PROFILES="${COMPOSE_PROFILES},local-database"
    echo "✅ Including local orchestrator service"
else
    echo "ℹ️  Skipping orchestrator service (using remote database)"
fi

# Add proxy if requested
if [ "${USE_PROXY:-false}" = "true" ]; then
    COMPOSE_PROFILES="${COMPOSE_PROFILES},proxy"
    echo "✅ Including Caddy proxy service"
fi

# Remove leading comma if present
COMPOSE_PROFILES=$(echo "$COMPOSE_PROFILES" | sed 's/^,//')

echo "🐳 Docker Compose profiles: $COMPOSE_PROFILES"

# Start services with appropriate profiles
if [ -n "$COMPOSE_PROFILES" ]; then
    COMPOSE_PROFILES="$COMPOSE_PROFILES" compose up -d --build
else
    compose up -d --build
fi

# Wait for services to be ready
echo "⏳ Waiting for services to start..."
sleep 10

# Check service health
echo "🏥 Checking service health..."

# Check LibreChat
if curl -sf http://localhost:3080 > /dev/null 2>&1; then
    echo "✅ LibreChat is running at http://localhost:3080"
else
    echo "❌ LibreChat is not responding"
fi

# Check orchestrator (only if running locally)
if [ "$MCP_DATABASE_MODE" = "local" ] || [ "$MCP_MODE" = "local" ] || [ "$MCP_MODE" = "hybrid" ]; then
    if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ Orchestrator API is running at http://localhost:3000"
    else
        echo "❌ Orchestrator API is not responding"
    fi
fi

# Test remote connectivity if using remote mode
if [ "$MCP_DATABASE_MODE" = "remote" ] && [ -n "$MCP_D1_DATABASE_URL" ]; then
    echo "🌐 Testing remote D1 database connectivity..."
    if curl -sf "${MCP_D1_DATABASE_URL}/health" > /dev/null 2>&1; then
        echo "✅ Remote D1 database is reachable"
    else
        echo "⚠️  Cannot reach remote D1 database (may affect functionality)"
    fi
fi

if [ "$MCP_INSTRUCTIONS_MODE" = "remote" ] && [ -n "$MCP_PROMPT_INSTRUCTIONS_URL" ]; then
    echo "🌐 Testing remote prompt instructions connectivity..."
    if curl -sf "${MCP_PROMPT_INSTRUCTIONS_URL}/health" > /dev/null 2>&1; then
        echo "✅ Remote prompt instructions server is reachable"
    else
        echo "⚠️  Cannot reach remote prompt instructions server"
    fi
fi

echo ""
echo "🎉 VoygentCE Services Started Successfully!"
echo "=========================================="
echo ""
echo "🌐 Access Points:"
echo "   • LibreChat UI: http://localhost:3080"
if [ "$MCP_DATABASE_MODE" = "local" ] || [ "$MCP_MODE" = "local" ] || [ "$MCP_MODE" = "hybrid" ]; then
    echo "   • API Health:   http://localhost:3000/health"
fi
echo ""
echo "📋 Service Configuration:"
echo "   • Browser automation: Local (mcp-chrome)"
echo "   • Trip/hotel data: $MCP_DATABASE_MODE mode"
echo "   • Workflow instructions: $MCP_INSTRUCTIONS_MODE mode"
echo ""
echo "🔧 Management Commands:"
echo "   • View logs: docker compose logs -f"
echo "   • Stop services: docker compose down"
echo "   • Restart: docker compose restart"
echo ""
echo "Ready for travel planning! 🧳✈️"
