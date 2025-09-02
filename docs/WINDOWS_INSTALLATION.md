# VoygentCE Windows Installation Guide

## Prerequisites

### 1. Install Required Software

#### Docker Desktop
- Download from: https://docs.docker.com/desktop/install/windows/
- Install and restart your computer
- Ensure Docker Desktop is running (check system tray)

#### Node.js (18+)
- Download from: https://nodejs.org/
- Choose LTS version (18 or higher)
- Verify: `node --version` should show v18.x.x or higher

#### Git for Windows
- Download from: https://git-scm.com/download/win
- Install with default options (includes Git Bash)
- Verify: `git --version`

#### Google Chrome
- Download from: https://www.google.com/chrome/
- Required for mcp-chrome browser automation

#### pnpm Package Manager
Install via PowerShell:
```powershell
npm install -g pnpm
```
Verify: `pnpm --version`

## Installation Steps

### Step 1: Clone the Repository

Open Git Bash or PowerShell:
```bash
git clone https://github.com/iamneilroberts/voygent.appCE.git
cd voygent.appCE
```

### Step 2: Configure Environment

#### For Remote MCP Servers (using existing infrastructure):
```bash
cp .env.example .env
# Edit .env file with your text editor
```

Set these values in `.env`:
```ini
# Remote mode configuration
MCP_MODE=remote
MCP_DATABASE_MODE=remote
MCP_INSTRUCTIONS_MODE=remote

# Your remote server URLs
MCP_D1_DATABASE_URL=https://d1-database-improved.somotravel.workers.dev
MCP_D1_DATABASE_SSE_URL=https://d1-database-improved.somotravel.workers.dev/sse
MCP_PROMPT_INSTRUCTIONS_URL=https://prompt-instructions-d1-mcp.somotravel.workers.dev
MCP_PROMPT_INSTRUCTIONS_SSE_URL=https://prompt-instructions-d1-mcp.somotravel.workers.dev/sse

# Auth key (if your servers require authentication)
MCP_AUTH_KEY=your-auth-key-here

# AI Provider Keys (at least one required)
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
# OPENAI_API_KEY=sk-your-key-here
```

#### For Local Mode (default, no external dependencies):
```ini
# Local mode configuration
MCP_MODE=local
MCP_DATABASE_MODE=local
MCP_INSTRUCTIONS_MODE=local

# AI Provider Keys (at least one required)
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
# OPENAI_API_KEY=sk-your-key-here
```

### Step 3: Run Setup Script

Use Git Bash (recommended for bash scripts):
```bash
./scripts/setup.sh
```

The script will:
1. Check prerequisites
2. Install pnpm if needed
3. Build mcp-chrome
4. Configure LibreChat
5. Start Docker services

**Note**: If you get a "pnpm is not recognized" error, install it manually first:
```powershell
npm install -g pnpm
```

### Step 4: Install Chrome Extension

#### Build the Extension:
```bash
cd mcp-chrome
pnpm build
```

#### Load in Chrome:
1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode" (top right toggle)
3. Click "Load unpacked"
4. Navigate to and select: `voygent.appCE\mcp-chrome\app\chrome-extension\.output\chrome-mv3`
5. The "Chrome MCP Server" extension should appear

#### Register Native Messaging Host:
Run in PowerShell as Administrator:
```powershell
cd mcp-chrome\app\native-server
npm run register
```

This allows the Chrome extension to communicate with the local MCP server.

### Step 5: Verify Installation

1. **Check Docker Services**:
   ```bash
   docker ps
   ```
   You should see:
   - librechat
   - mongodb
   - meilisearch
   - orchestrator (if using local mode)

2. **Access LibreChat**:
   - Open browser to: http://localhost:3080
   - Create an account
   - Start a conversation

3. **Test Chrome Extension**:
   - Click the mcp-chrome icon in Chrome toolbar
   - Should show "Connected" status

4. **Test MCP Integration**:
   In LibreChat, try:
   ```
   /start
   ```
   This should initialize the travel agent system.

## Troubleshooting

### Common Issues

#### "pnpm is not recognized"
```powershell
# Install pnpm globally
npm install -g pnpm

# Verify installation
pnpm --version

# Restart your terminal/Git Bash
```

#### Docker not starting
- Ensure Docker Desktop is running (check system tray)
- Try restarting Docker Desktop
- Check WSL2 is installed: `wsl --status`

#### Port already in use
```bash
# Stop all containers
docker-compose down

# Check what's using port 3080
netstat -ano | findstr :3080

# Kill the process if needed
taskkill /PID <process-id> /F
```

#### Chrome extension not connecting
1. Check native host registration:
   ```powershell
   # Re-register the native host
   cd mcp-chrome\app\native-server
   npm run register
   ```

2. Check Chrome DevTools console (F12 in extension popup)

3. Ensure the extension has necessary permissions

#### LibreChat MCP tools not showing
1. Regenerate config:
   ```bash
   ./scripts/configure-librechat.sh
   ```

2. Restart LibreChat:
   ```bash
   docker-compose restart librechat
   ```

### Windows-Specific Tips

1. **Use Git Bash** for running bash scripts (`.sh` files)
2. **Run PowerShell as Administrator** for native host registration
3. **Keep Docker Desktop running** during use
4. **Check Windows Firewall** if services can't connect
5. **WSL2 recommended** for better Docker performance

## File Paths on Windows

- Chrome extension location: `C:\path\to\voygent.appCE\mcp-chrome\app\chrome-extension\.output\chrome-mv3`
- Logs: `C:\path\to\voygent.appCE\data\logs`
- Database (SQLite): `C:\path\to\voygent.appCE\data\voygen.sqlite`

## Getting Help

- Check logs: `docker-compose logs -f`
- View service status: `docker ps`
- GitHub Issues: https://github.com/iamneilroberts/voygent.appCE/issues

## Next Steps

Once everything is running:

1. **Local Mode Users**: Your data stays on your machine, start planning trips!
2. **Remote Mode Users**: You're connected to your Cloudflare infrastructure
3. **Test the workflow**: Try `/continue` to resume work on existing trips

The system is now ready for travel planning! 🧳✈️