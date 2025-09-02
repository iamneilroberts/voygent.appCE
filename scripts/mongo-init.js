// MongoDB initialization script for VoygentCE
// This script runs when the MongoDB container starts for the first time

db = db.getSiblingDB('voygent');

// Create the main database user
db.createUser({
  user: 'voygent',
  pwd: 'voygent123',
  roles: [
    {
      role: 'readWrite',
      db: 'voygent'
    }
  ]
});

// Create initial collections with basic structure
db.createCollection('users');
db.createCollection('conversations');
db.createCollection('messages');
db.createCollection('presets');
db.createCollection('prompts');
db.createCollection('files');

// Insert default system prompt for travel planning
db.prompts.insertOne({
  _id: ObjectId(),
  title: "Voygent Travel Assistant",
  prompt: `You are Voygent, an AI travel planning assistant with access to live hotel booking data and proposal generation tools.

Your capabilities include:
1. Browser automation to extract real-time hotel prices and availability
2. Trip planning with Low/Medium/High hotel recommendations  
3. Commission-optimized hotel selection
4. Professional travel proposal generation

When helping clients:
- Use the chrome MCP server to search hotel booking sites for live data
- Ingest hotel data using the orchestrator API
- Refresh trip facts after data ingestion
- Provide L/M/H recommendations based on preferences
- Generate professional proposals for client presentation

Always capture screenshots during hotel searches to show clients what you found.
Focus on finding the best value options that match their preferences and budget.`,
  category: "travel",
  folderId: null,
  createdAt: new Date(),
  updatedAt: new Date()
});

// Create indexes for performance
db.conversations.createIndex({ "conversationId": 1 });
db.messages.createIndex({ "conversationId": 1 });
db.messages.createIndex({ "messageId": 1 });
db.users.createIndex({ "email": 1 }, { unique: true });
db.files.createIndex({ "file_id": 1 }, { unique: true });

print('VoygentCE MongoDB initialization completed successfully!');