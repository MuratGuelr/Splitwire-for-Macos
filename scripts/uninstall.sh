#!/usr/bin/env bash
set -euo pipefail

PLIST_FILE="$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
LAUNCHER_PLIST_FILE="$HOME/Library/LaunchAgents/net.consolaktif.discord.launcher.plist"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
SCRIPT_FILE="$APP_SUPPORT_DIR/discord-spoofdpi.sh"
STATE_DIR="$APP_SUPPORT_DIR/state"

# servisleri durdur + kaldır
launchctl stop net.consolaktif.discord.spoofdpi 2>/dev/null || true
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl stop net.consolaktif.discord.launcher 2>/dev/null || true
launchctl unload "$LAUNCHER_PLIST_FILE" 2>/dev/null || true

# dosyaları sil
rm -f "$PLIST_FILE" "$LAUNCHER_PLIST_FILE" "$SCRIPT_FILE"

# brew ile kurduysak kaldır
if [[ -f "$STATE_DIR/.installed_spoofdpi_via_brew" ]] && command -v brew >/dev/null 2>&1; then
  brew list spoofdpi >/dev/null 2>&1 && brew uninstall spoofdpi || true
  rm -f "$STATE_DIR/.installed_spoofdpi_via_brew"
fi

echo "Kaldırma tamam. İsterseniz $APP_SUPPORT_DIR klasörünü de silebilirsiniz."