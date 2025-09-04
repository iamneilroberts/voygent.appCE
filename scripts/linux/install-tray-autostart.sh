#!/usr/bin/env bash
set -euo pipefail

# Adds an XDG autostart .desktop entry to run the Voygent Tray app (Electron)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
TRAY_DIR="$REPO_DIR/tray"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
mkdir -p "$AUTOSTART_DIR"

cat >"$AUTOSTART_DIR/voygent-tray.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Voygent CE Tray
Comment=Tray controller for Voygent CE services
Exec=sh -lc 'cd "$TRAY_DIR" && pnpm dev'
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo "✅ Installed tray autostart at $AUTOSTART_DIR/voygent-tray.desktop"
echo "Note: run 'cd "$TRAY_DIR" && pnpm install' once before autostart will work."

