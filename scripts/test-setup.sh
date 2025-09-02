#!/bin/bash
# VoygentCE Test Script
# This script tests the complete VoygentCE system functionality

set -e

echo "🧪 VoygentCE System Test"
echo "========================"

# Check if services are running
echo "🔍 Checking service health..."

# Test orchestrator
echo "Testing Orchestrator API..."
HEALTH_RESPONSE=$(curl -s http://localhost:3000/health || echo "FAILED")
if [[ $HEALTH_RESPONSE == *"ok"* ]]; then
    echo "✅ Orchestrator API is healthy"
else
    echo "❌ Orchestrator API is not responding"
    echo "Response: $HEALTH_RESPONSE"
    exit 1
fi

# Test LibreChat
echo "Testing LibreChat UI..."
if curl -sf http://localhost:3080 > /dev/null; then
    echo "✅ LibreChat UI is accessible"
else
    echo "❌ LibreChat UI is not responding"
    exit 1
fi

# Test database connectivity
echo "🗄️ Testing database operations..."

# Create a test trip
echo "Creating test trip..."
CREATE_RESPONSE=$(curl -s -X POST http://localhost:3000/api/trips \
    -H "Content-Type: application/json" \
    -d '{
        "id": "test_trip_123",
        "title": "System Test Trip",
        "party": [{"name": "Test User", "role": "traveler"}],
        "destinations": "Test City"
    }')

if [[ $CREATE_RESPONSE == *"ok"* ]]; then
    echo "✅ Trip creation successful"
else
    echo "❌ Trip creation failed"
    echo "Response: $CREATE_RESPONSE"
    exit 1
fi

# Ingest sample hotel data
echo "Testing hotel data ingestion..."
INGEST_RESPONSE=$(curl -s -X POST http://localhost:3000/api/ingest/hotels \
    -H "Content-Type: application/json" \
    -d '{
        "trip_id": "test_trip_123",
        "city": "Test City",
        "site": "test",
        "hotels": [
            {
                "site": "test",
                "name": "Test Hotel",
                "city": "Test City",
                "lead_price": {"amount": 150, "currency": "USD"},
                "refundable": true
            },
            {
                "site": "test",
                "name": "Budget Test Inn",
                "city": "Test City", 
                "lead_price": {"amount": 89, "currency": "USD"},
                "refundable": false
            }
        ]
    }')

if [[ $INGEST_RESPONSE == *"ok"* ]]; then
    echo "✅ Hotel ingestion successful"
else
    echo "❌ Hotel ingestion failed"
    echo "Response: $INGEST_RESPONSE"
    exit 1
fi

# Refresh trip facts
echo "Testing fact refresh..."
REFRESH_RESPONSE=$(curl -s -X POST http://localhost:3000/api/facts/refresh/test_trip_123)

if [[ $REFRESH_RESPONSE == *"ok"* ]]; then
    echo "✅ Fact refresh successful"
else
    echo "❌ Fact refresh failed" 
    echo "Response: $REFRESH_RESPONSE"
    exit 1
fi

# Test L/M/H recommendations
echo "Testing recommendation engine..."
RECOMMEND_RESPONSE=$(curl -s -X POST http://localhost:3000/api/plan/city \
    -H "Content-Type: application/json" \
    -d '{
        "trip_id": "test_trip_123",
        "city": "Test City",
        "prefs": {"refundable": true}
    }')

if [[ $RECOMMEND_RESPONSE == *"recommendations"* ]]; then
    echo "✅ Recommendation engine working"
else
    echo "❌ Recommendation engine failed"
    echo "Response: $RECOMMEND_RESPONSE"
    exit 1
fi

# Test proposal generation
echo "Testing proposal generation..."
PROPOSAL_RESPONSE=$(curl -s -X POST http://localhost:3000/api/proposal/render \
    -H "Content-Type: application/json" \
    -d '{
        "trip_id": "test_trip_123",
        "template": "basic"
    }')

if [[ $PROPOSAL_RESPONSE == *"content"* ]]; then
    echo "✅ Proposal generation working"
else
    echo "❌ Proposal generation failed"
    echo "Response: $PROPOSAL_RESPONSE"
    exit 1
fi

# Test MCP Chrome (if available)
echo "🌐 Testing MCP Chrome connectivity..."
if [ -d "mcp-chrome" ] && [ -f "mcp-chrome/package.json" ]; then
    cd mcp-chrome
    if npm list > /dev/null 2>&1; then
        echo "✅ MCP Chrome dependencies installed"
    else
        echo "⚠️  MCP Chrome dependencies not installed"
        echo "   Run: cd mcp-chrome && npm install"
    fi
    cd ..
else
    echo "⚠️  MCP Chrome not found - browser automation will not work"
fi

echo ""
echo "🎉 System Test Complete!"
echo "========================"
echo ""
echo "✅ All core functionality tests passed"
echo ""
echo "🔗 Quick Links:"
echo "   • LibreChat UI:    http://localhost:3080"
echo "   • API Health:      http://localhost:3000/health"
echo "   • Test Trip:       http://localhost:3000/api/trips (GET)"
echo ""
echo "📊 Test Results Summary:"
echo "   • ✅ Orchestrator API: Working"
echo "   • ✅ LibreChat UI: Accessible" 
echo "   • ✅ Database Operations: Working"
echo "   • ✅ Hotel Ingestion: Working"
echo "   • ✅ Fact Processing: Working"
echo "   • ✅ Recommendations: Working"
echo "   • ✅ Proposal Generation: Working"
echo ""
echo "🚀 Your VoygentCE system is fully functional!"