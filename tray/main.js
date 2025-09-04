import { app, Tray, Menu, shell, nativeImage, dialog } from 'electron'
import fs from 'node:fs/promises'
import { spawn } from 'node:child_process'
import path from 'node:path'
import os from 'node:os'

// On many Linux setups, Electron's setuid sandbox isn't configured during dev.
// For dev convenience we disable it on Linux unless explicitly overridden.
if (process.platform === 'linux' && process.env.VOYGENT_TRAY_ENABLE_SANDBOX !== '1' && process.env.ELECTRON_ENABLE_SANDBOX !== '1') {
  app.commandLine.appendSwitch('no-sandbox')
  app.commandLine.appendSwitch('disable-gpu-sandbox')
}

// Minimal neutral tray icon via 1x1 transparent PNG so we always have an icon.
// Tooltip + menu labels provide the health indicator (🟢/🟡/🔴).
const TRANSPARENT_PNG = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg=='

let REPO_ROOT = null
let VOYGENT_CMD = null

const SITES = {
  librechat: 'http://localhost:3080',
  meili: 'http://localhost:7700/health',
  orchestrator: 'http://localhost:3000/health'
}

let tray
let status = { healthy: false, partial: false, details: {} }
let checking = false
let menu

function configDir() {
  if (process.platform === 'win32') return path.join(process.env.APPDATA || path.join(os.homedir(), 'AppData', 'Roaming'), 'Voygent')
  if (process.platform === 'darwin') return path.join(os.homedir(), 'Library', 'Application Support', 'Voygent')
  return path.join(process.env.XDG_CONFIG_HOME || path.join(os.homedir(), '.config'), 'voygent')
}

function configPath() {
  return path.join(configDir(), 'tray.json')
}

async function loadConfig() {
  try {
    const c = JSON.parse(await fs.readFile(configPath(), 'utf8'))
    return c
  } catch (_) {
    return {}
  }
}

async function saveConfig(cfg) {
  try {
    await fs.mkdir(configDir(), { recursive: true })
    await fs.writeFile(configPath(), JSON.stringify(cfg, null, 2))
  } catch (e) {
    console.warn('Failed to save config:', e)
  }
}

async function pathExists(p) {
  try { await fs.access(p); return true } catch { return false }
}

async function detectRepoRoot() {
  // 1) Environment override
  const envRoot = process.env.VOYGENT_ROOT
  if (envRoot) {
    if (await pathExists(path.join(envRoot, process.platform === 'win32' ? 'voygent.bat' : 'voygent'))) return envRoot
  }

  // 2) Stored config
  const cfg = await loadConfig()
  if (cfg.repoRoot && await pathExists(path.join(cfg.repoRoot, process.platform === 'win32' ? 'voygent.bat' : 'voygent'))) return cfg.repoRoot

  // 3) Common paths relative to app
  const candidates = [
    path.resolve(path.join(app.getAppPath(), '..', '..')), // unpacked dev run
    path.resolve(path.join(app.getAppPath(), '..')),       // another dev layout
    process.cwd(),
    path.join(os.homedir(), 'dev', 'voygent.appCE'),
  ]
  for (const c of candidates) {
    if (await pathExists(path.join(c, process.platform === 'win32' ? 'voygent.bat' : 'voygent'))) return c
  }

  // 4) Ask the user
  const res = await dialog.showOpenDialog({
    title: 'Locate Voygent CE folder',
    message: 'Select the folder that contains the voygent launcher script',
    properties: ['openDirectory']
  })
  if (!res.canceled && res.filePaths && res.filePaths[0]) {
    const chosen = res.filePaths[0]
    if (await pathExists(path.join(chosen, process.platform === 'win32' ? 'voygent.bat' : 'voygent'))) {
      await saveConfig({ repoRoot: chosen })
      return chosen
    }
    dialog.showErrorBox('Voygent', 'Selected directory does not contain voygent/voygent.bat')
  }
  return null
}

async function ensureCommands() {
  if (!REPO_ROOT) REPO_ROOT = await detectRepoRoot()
  if (!REPO_ROOT) return false
  VOYGENT_CMD = process.platform === 'win32'
    ? { cmd: 'cmd', args: ['/c', 'voygent.bat'], cwd: REPO_ROOT }
    : { cmd: path.join(REPO_ROOT, 'voygent'), args: [], cwd: REPO_ROOT }
  return true
}

async function ping(url) {
  try {
    const c = new AbortController()
    const t = setTimeout(() => c.abort(), 3000)
    const res = await fetch(url, { signal: c.signal })
    clearTimeout(t)
    return res.ok
  } catch (_) {
    return false
  }
}

async function checkHealth() {
  if (checking) return
  checking = true
  await ensureCommands()
  const [lc, meili, orch] = await Promise.all([
    ping(SITES.librechat),
    ping(SITES.meili),
    ping(SITES.orchestrator)
  ])
  const upCount = [lc, meili, orch].filter(Boolean).length
  status.details = { librechat: lc, meilisearch: meili, orchestrator: orch }
  status.healthy = upCount >= 2 && lc // consider healthy if LibreChat + one backend
  status.partial = !status.healthy && upCount > 0
  updateMenu()
  checking = false
}

function runVoygent(sub) {
  if (!VOYGENT_CMD) {
    dialog.showErrorBox('Voygent', 'Voygent path not set. Use "Set Repo Path..." from the tray menu.')
    return
  }
  const isWin = process.platform === 'win32'
  const args = [...VOYGENT_CMD.args, sub]
  const child = spawn(VOYGENT_CMD.cmd, args, {
    cwd: VOYGENT_CMD.cwd,
    shell: false,
    stdio: 'ignore'
  })
  child.on('error', (e) => {
    dialog.showErrorBox('Voygent', `Failed to run command: ${sub}\n\n${e.message}`)
  })
}

function statusEmoji() {
  if (status.healthy) return '🟢'
  if (status.partial) return '🟡'
  return '🔴'
}

function statusTooltip() {
  const d = status.details
  return `Voygent CE\nLibreChat: ${d.librechat ? 'up' : 'down'}\nMeili: ${d.meilisearch ? 'up' : 'down'}\nOrchestrator: ${d.orchestrator ? 'up' : 'down'}`
}

function updateMenu() {
  if (!tray) return
  tray.setToolTip(statusTooltip())
  const items = [
    { label: `${statusEmoji()} Status: ${status.healthy ? 'Healthy' : status.partial ? 'Degraded' : 'Stopped'}`, enabled: false },
    { type: 'separator' },
    { label: 'Open LibreChat UI', click: () => shell.openExternal(SITES.librechat) },
    { label: 'Start Services', click: () => runVoygent('start') },
    { label: 'Stop Services', click: () => runVoygent('stop') },
    { label: 'Restart Services', click: () => runVoygent('restart') },
    { label: 'Set Repo Path...', click: async () => { REPO_ROOT = null; await ensureCommands(); updateMenu() } },
    { type: 'separator' },
    { label: 'Health Check Now', click: () => checkHealth() },
    { label: 'Show Status (terminal)', click: () => runVoygent('status') },
    { type: 'separator' },
    { label: 'Quit Tray', click: () => app.quit() }
  ]
  menu = Menu.buildFromTemplate(items)
  tray.setContextMenu(menu)
}

function createTray() {
  const img = nativeImage.createFromDataURL(`data:image/png;base64,${TRANSPARENT_PNG}`)
  tray = new Tray(img)
  tray.setIgnoreDoubleClickEvents(true)
  tray.on('click', () => {
    checkHealth()
  })
  updateMenu()
  checkHealth()
  setInterval(checkHealth, 10000)
}

app.on('ready', createTray)
app.on('window-all-closed', (e) => e.preventDefault())
app.on('before-quit', () => { /* noop */ })
