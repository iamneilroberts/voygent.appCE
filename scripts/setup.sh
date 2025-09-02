#!/bin/bash
# VoygentCE Setup Script
# This script sets up the complete VoygentCE system

set -e

echo "🚀 VoygentCE Setup Starting..."
echo "================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "   Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Check if Node.js is installed (for mcp-chrome)
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "   Visit: https://nodejs.org/"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node --version | cut -d'.' -f1 | cut -d'v' -f2)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18 or higher is required. Current version: $(node --version)"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Create environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating environment file..."
    cp .env.example .env
    echo "✅ Created .env file from template"
    echo ""
    
    # MCP Mode Selection
    echo "🔧 MCP Server Configuration"
    echo "=============================="
    echo ""
    echo "VoygentCE can run in different MCP server modes:"
    echo ""
    echo "1) LOCAL (default) - Fully self-contained"
    echo "   • All data stored locally (SQLite/PostgreSQL)"
    echo "   • Complete privacy and control"
    echo "   • No external dependencies"
    echo "   • Best for: Privacy-focused users, offline work"
    echo ""
    echo "2) REMOTE - Connect to existing Cloudflare Workers"  
    echo "   • Use your existing d1-database and prompt-instructions servers"
    echo "   • Shared data across installations"
    echo "   • Advanced features and automatic backups"
    echo "   • Best for: Users with existing Voygen infrastructure"
    echo ""
    echo "3) HYBRID - Mix local and remote"
    echo "   • Flexible per-component configuration"
    echo "   • Keep data local, share workflows"
    echo "   • Best for: Advanced users wanting custom setups"
    echo ""
    
    while true; do
        read -p "Select MCP mode [1=Local, 2=Remote, 3=Hybrid] (default: 1): " mcp_choice
        case ${mcp_choice:-1} in
            1)
                echo "MCP_MODE=local" >> .env
                echo "MCP_DATABASE_MODE=local" >> .env
                echo "MCP_INSTRUCTIONS_MODE=local" >> .env
                echo "✅ Configured for LOCAL mode"
                break
                ;;
            2)
                echo "MCP_MODE=remote" >> .env
                echo "MCP_DATABASE_MODE=remote" >> .env  
                echo "MCP_INSTRUCTIONS_MODE=remote" >> .env
                echo "✅ Configured for REMOTE mode"
                echo ""
                echo "⚠️  IMPORTANT: You must configure remote server URLs in .env:"
                echo "   - MCP_D1_DATABASE_URL"
                echo "   - MCP_D1_DATABASE_SSE_URL"
                echo "   - MCP_PROMPT_INSTRUCTIONS_URL"
                echo "   - MCP_PROMPT_INSTRUCTIONS_SSE_URL"
                echo "   - MCP_AUTH_KEY"
                break
                ;;
            3)
                echo "MCP_MODE=hybrid" >> .env
                echo "✅ Configured for HYBRID mode"
                echo ""
                echo "⚠️  IMPORTANT: Configure individual component modes in .env:"
                echo "   - MCP_DATABASE_MODE=local|remote"
                echo "   - MCP_INSTRUCTIONS_MODE=local|remote"
                echo "   - Add remote server URLs if using remote components"
                break
                ;;
            *)
                echo "❌ Invalid choice. Please select 1, 2, or 3."
                ;;
        esac
    done
    echo ""
    
    # API Keys configuration
    echo "🔑 API Keys Configuration"
    echo "========================="
    echo ""
    echo "VoygentCE requires at least one LLM provider API key:"
    echo ""
    read -p "Enter Anthropic API Key (recommended) [press Enter to skip]: " anthropic_key
    if [ -n "$anthropic_key" ]; then
        sed -i "s/ANTHROPIC_API_KEY=/ANTHROPIC_API_KEY=$anthropic_key/" .env
        echo "✅ Anthropic API key configured"
    fi
    
    read -p "Enter OpenAI API Key [press Enter to skip]: " openai_key
    if [ -n "$openai_key" ]; then
        sed -i "s/OPENAI_API_KEY=/OPENAI_API_KEY=$openai_key/" .env
        echo "✅ OpenAI API key configured"  
    fi
    
    if [ -z "$anthropic_key" ] && [ -z "$openai_key" ]; then
        echo "⚠️  No API keys configured. You'll need to edit .env manually before starting."
    fi
    
    echo ""
    read -p "Do you want to edit .env file for additional configuration? (y/n): " edit_env
    if [ "$edit_env" = "y" ] || [ "$edit_env" = "Y" ]; then
        ${EDITOR:-nano} .env
    fi
else
    echo "✅ Environment file already exists"
fi

# Create data directories
echo "📁 Creating data directories..."
mkdir -p data/mongodb
mkdir -p data/meilisearch
mkdir -p data/uploads
mkdir -p data/logs
mkdir -p data/proposals
echo "✅ Data directories created"

# Install mcp-chrome locally
echo "🌐 Installing mcp-chrome for browser automation..."
if [ -d "mcp-chrome" ]; then
    echo "📂 Installing mcp-chrome dependencies..."
    cd mcp-chrome
    npm install
    npm run build
    cd ..
    echo "✅ mcp-chrome installed locally"
else
    echo "❌ mcp-chrome directory not found. This is required for browser automation."
    exit 1
fi

# Build and start services
echo "🐳 Building and starting Docker services..."
docker-compose down -v 2>/dev/null || true

# Use the intelligent service startup script
./scripts/start-services.sh

# Initialize database with sample data (optional)
read -p "Do you want to initialize with sample data? (y/n): " init_sample
if [ "$init_sample" = "y" ] || [ "$init_sample" = "Y" ]; then
    echo "📊 Initializing sample data..."
    
    # Create a sample trip
    curl -s -X POST http://localhost:3000/api/trips \
        -H "Content-Type: application/json" \
        -d '{
            "id": "demo_trip_paris",
            "title": "Paris Weekend Getaway",
            "party": [{"name": "Demo User", "role": "traveler"}],
            "destinations": "Paris, France"
        }' > /dev/null
    
    echo "✅ Sample data initialized"
fi

echo ""
echo "🎉 VoygentCE Setup Complete!"
echo "============================"
echo ""
echo "🌐 Access your services:"
echo "   • LibreChat UI:    http://localhost:3080"
echo "   • Orchestrator API: http://localhost:3000"
echo "   • API Health:      http://localhost:3000/health"
echo ""
echo "📋 Next steps:"
echo "   1. Open http://localhost:3080 in your browser"
echo "   2. Create an account in LibreChat"
echo "   3. Start a conversation and begin planning trips!"
echo ""
echo "🔧 Troubleshooting:"
echo "   • Check logs: docker-compose logs"
echo "   • Restart services: docker-compose restart"
echo "   • View status: docker-compose ps"
echo ""
echo "📖 Documentation: README.md"
echo "🐛 Issues: https://github.com/iamneilroberts/voygent.appCE/issues"