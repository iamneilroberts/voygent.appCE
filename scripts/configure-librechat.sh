#!/bin/bash
# VoygentCE LibreChat Configuration Generator
# Generates librechat.yaml based on MCP_MODE environment variables

set -e

echo "🔧 Configuring LibreChat based on MCP mode..."

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set defaults if not specified
MCP_MODE=${MCP_MODE:-local}
MCP_DATABASE_MODE=${MCP_DATABASE_MODE:-local}
MCP_INSTRUCTIONS_MODE=${MCP_INSTRUCTIONS_MODE:-local}
MCP_CHROME_PATH=${MCP_CHROME_PATH:-./mcp-chrome/dist/index.js}

echo "📋 MCP Configuration:"
echo "   Mode: $MCP_MODE"
echo "   Database: $MCP_DATABASE_MODE"
echo "   Instructions: $MCP_INSTRUCTIONS_MODE"

# Override individual modes based on overall mode
if [ "$MCP_MODE" = "remote" ]; then
    MCP_DATABASE_MODE=remote
    MCP_INSTRUCTIONS_MODE=remote
elif [ "$MCP_MODE" = "local" ]; then
    MCP_DATABASE_MODE=local
    MCP_INSTRUCTIONS_MODE=local
fi

# Validate remote mode configuration
if [ "$MCP_DATABASE_MODE" = "remote" ]; then
    if [ -z "$MCP_D1_DATABASE_SSE_URL" ]; then
        echo "❌ MCP_D1_DATABASE_SSE_URL is required for remote database mode"
        echo "   Please set this in your .env file"
        exit 1
    fi
fi

if [ "$MCP_INSTRUCTIONS_MODE" = "remote" ]; then
    if [ -z "$MCP_PROMPT_INSTRUCTIONS_SSE_URL" ]; then
        echo "❌ MCP_PROMPT_INSTRUCTIONS_SSE_URL is required for remote instructions mode"
        echo "   Please set this in your .env file"
        exit 1
    fi
fi

# Create temporary processing script for template
cat > /tmp/process_template.js << 'EOF'
const fs = require('fs');
const path = require('path');

// Read template file
const templatePath = process.argv[2];
const outputPath = process.argv[3];
const template = fs.readFileSync(templatePath, 'utf8');

// Get environment variables
const env = process.env;
const databaseLocal = env.MCP_DATABASE_MODE === 'local';
const databaseRemote = env.MCP_DATABASE_MODE === 'remote';
const instructionsRemote = env.MCP_INSTRUCTIONS_MODE === 'remote';

console.log('Processing template with:', {
    databaseLocal,
    databaseRemote,
    instructionsRemote,
    chromePath: env.MCP_CHROME_PATH
});

// Simple template processor
let result = template;

// Process conditional blocks
if (databaseLocal) {
    result = result.replace(/\{\{#if_database_local\}\}([\s\S]*?)\{\{\/if_database_local\}\}/g, '$1');
} else {
    result = result.replace(/\{\{#if_database_local\}\}[\s\S]*?\{\{\/if_database_local\}\}/g, '');
}

if (databaseRemote) {
    result = result.replace(/\{\{#if_database_remote\}\}([\s\S]*?)\{\{\/if_database_remote\}\}/g, '$1');
} else {
    result = result.replace(/\{\{#if_database_remote\}\}[\s\S]*?\{\{\/if_database_remote\}\}/g, '');
}

if (instructionsRemote) {
    result = result.replace(/\{\{#if_instructions_remote\}\}([\s\S]*?)\{\{\/if_instructions_remote\}\}/g, '$1');
} else {
    result = result.replace(/\{\{#if_instructions_remote\}\}[\s\S]*?\{\{\/if_instructions_remote\}\}/g, '');
}

// Process environment variable substitutions
result = result.replace(/\$\{([^}]+)\}/g, (match, varName) => {
    return env[varName] || match;
});

// Write output
fs.writeFileSync(outputPath, result);
console.log('✅ Generated:', outputPath);
EOF

# Process the template
echo "🏗️ Generating LibreChat configuration..."
node /tmp/process_template.js config/librechat-template.yaml config/librechat.yaml

# Clean up temporary file
rm -f /tmp/process_template.js

# Validate Chrome MCP path
if [ ! -f "$MCP_CHROME_PATH" ]; then
    echo "⚠️  Chrome MCP path not found: $MCP_CHROME_PATH"
    echo "   Make sure mcp-chrome is installed and built"
    echo "   Run: cd mcp-chrome && npm install && npm run build"
fi

# Test remote connectivity if using remote mode
if [ "$MCP_DATABASE_MODE" = "remote" ]; then
    echo "🌐 Testing D1 database connectivity..."
    if curl -sf "$MCP_D1_DATABASE_URL/health" > /dev/null; then
        echo "✅ D1 database server is reachable"
    else
        echo "❌ Cannot reach D1 database server at $MCP_D1_DATABASE_URL"
        echo "   Check your MCP_D1_DATABASE_URL setting"
    fi
fi

if [ "$MCP_INSTRUCTIONS_MODE" = "remote" ]; then
    echo "🌐 Testing prompt instructions connectivity..."
    if curl -sf "$MCP_PROMPT_INSTRUCTIONS_URL/health" > /dev/null; then
        echo "✅ Prompt instructions server is reachable"
    else
        echo "❌ Cannot reach prompt instructions server at $MCP_PROMPT_INSTRUCTIONS_URL"
        echo "   Check your MCP_PROMPT_INSTRUCTIONS_URL setting"
    fi
fi

echo ""
echo "✅ LibreChat configuration generated successfully!"
echo ""
echo "📋 Configuration Summary:"
echo "   • Browser automation: Local (mcp-chrome)"
echo "   • Trip/hotel data: $MCP_DATABASE_MODE mode"
echo "   • Workflow instructions: $MCP_INSTRUCTIONS_MODE mode"
echo ""
echo "🚀 LibreChat will use these MCP servers when started"

# Show generated config summary
echo ""
echo "📝 Generated config/librechat.yaml with $(grep -c 'mcpServers:' config/librechat.yaml || echo '0') MCP server(s):"
grep -A1 "  [a-z_]*:" config/librechat.yaml | grep -E "^  [a-z_]+:" | sed 's/://g' | while read server; do
    echo "   • $server"
done || echo "   • chrome (browser automation)"