#!/usr/bin/env bash
set -euo pipefail

# Tiny wrapper to start Voygent CE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
exec ./voygent start "$@"

