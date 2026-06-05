#!/usr/bin/env bash
# Installer for the Chromium Wayland cedilla fix (Arch Linux / Arch Linux ARM).
# Installs the patch script + a pacman hook that re-applies it after every
# Chromium upgrade, then applies the patch once.
set -euo pipefail

BIN="${1:-/usr/lib/chromium/chromium}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -ne 0 ]]; then
    echo "This installer needs root. Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

echo ">> Installing patch script to /usr/local/bin"
install -Dm755 "$SCRIPT_DIR/chromium-cedilla-patch.py" /usr/local/bin/chromium-cedilla-patch.py

echo ">> Installing pacman hook to /etc/pacman.d/hooks"
install -Dm644 "$SCRIPT_DIR/chromium-cedilla.hook" /etc/pacman.d/hooks/chromium-cedilla.hook

echo ">> Applying patch now"
python3 /usr/local/bin/chromium-cedilla-patch.py "$BIN"

echo
echo "Done. Restart Chromium completely and test ' + c (should produce ç)."
