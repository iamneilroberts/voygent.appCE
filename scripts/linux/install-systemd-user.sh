#!/usr/bin/env bash
set -euo pipefail

# Installs a systemd --user service to auto-start Voygent CE

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$UNIT_DIR"

cat >"$UNIT_DIR/voygent.service" <<EOF
[Unit]
Description=Voygent CE (Docker Compose)
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
WorkingDirectory=%h
ExecStart=%h/voygent.appCE/voygent start
ExecStop=%h/voygent.appCE/voygent stop
Restart=on-failure
RestartSec=5s
TimeoutStartSec=0

[Install]
WantedBy=default.target
EOF

# Replace %h/voygent.appCE with the real absolute repo path for this install
sed -i "s|%h/voygent.appCE|${REPO_DIR//$HOME/%h}|" "$UNIT_DIR/voygent.service"
sed -i "s|WorkingDirectory=%h|WorkingDirectory=${REPO_DIR//$HOME/%h}|" "$UNIT_DIR/voygent.service"

systemctl --user daemon-reload || true
if systemctl --user enable --now voygent.service; then
  echo "✅ Enabled and started systemd --user service 'voygent.service'"
else
  echo "⚠️  Could not start service automatically. This can happen if user lingering is disabled."
  echo "   You can enable lingering with: sudo loginctl enable-linger $USER"
  echo "   Then rerun: systemctl --user enable --now voygent.service"
fi

echo "Service file: $UNIT_DIR/voygent.service"

