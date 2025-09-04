#!/usr/bin/env bash
set -euo pipefail

# Installs both a systemd --user service and an XDG autostart .desktop as a fallback

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔧 Installing systemd --user service..."
"$SCRIPT_DIR/install-systemd-user.sh" || true

echo "🔧 Installing XDG autostart entry..."
AUTOSTART_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/autostart"
mkdir -p "$AUTOSTART_DIR"
cat >"$AUTOSTART_DIR/voygent.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Voygent CE
Comment=Start Voygent CE services
Exec=${REPO_DIR}/start.sh
Terminal=false
X-GNOME-Autostart-enabled=true
EOF

echo "✅ Installed autostart entry at $AUTOSTART_DIR/voygent.desktop"
echo "Done. On next login, Voygent CE will auto-start (systemd user or XDG)."

