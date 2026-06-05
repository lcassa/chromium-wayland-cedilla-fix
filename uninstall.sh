#!/usr/bin/env bash
# Uninstaller: removes the pacman hook and the patch script, and restores the
# pristine Chromium binary if a .orig backup exists.
set -euo pipefail

BIN="${1:-/usr/lib/chromium/chromium}"

if [[ $EUID -ne 0 ]]; then
    echo "This uninstaller needs root. Re-running with sudo..."
    exec sudo bash "$0" "$@"
fi

echo ">> Removing pacman hook"
rm -f /etc/pacman.d/hooks/chromium-cedilla.hook

echo ">> Removing patch script"
rm -f /usr/local/bin/chromium-cedilla-patch.py

if [[ -f "$BIN.orig" ]]; then
    echo ">> Restoring pristine binary from $BIN.orig"
    cp -a "$BIN.orig" "$BIN"
else
    echo ">> No $BIN.orig found; the next 'pacman -S chromium' reinstall will"
    echo "   restore an unpatched binary anyway."
fi

echo "Done."
