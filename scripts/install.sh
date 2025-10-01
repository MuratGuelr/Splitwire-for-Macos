#!/usr/bin/env bash
set -euo pipefail

# ---------- Homebrew yoksa kur ----------
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew bulunamadı, kuruluyor…"
  bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-homebrew.sh"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
# ----------------------------------------

# ---------- Discord kontrolü ----------
if [[ ! -d "/Applications/Discord.app" ]]; then
  echo "❌  Discord uygulaması /Applications klasöründe bulunamadı."
  echo "   Lütfen Discord’u indirip /Applications klasörüne taşıyın ve tekrar çalıştırın."
  exit 1
fi
# ----------------------------------------

PLIST_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/launchd"
PLIST_FILE="net.consolaktif.discord.spoofdpi.plist"
LAUNCHER_PLIST_FILE="net.consolaktif.discord.launcher.plist"
TARGET_PLIST="$HOME/Library/LaunchAgents/$PLIST_FILE"
TARGET_LAUNCHER_PLIST="$HOME/Library/LaunchAgents/$LAUNCHER_PLIST_FILE"

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
SCRIPT_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_FILE="discord-spoofdpi.sh"
TARGET_SCRIPT="$APP_SUPPORT_DIR/$SCRIPT_FILE"
STATE_DIR="$APP_SUPPORT_DIR/state"

mkdir -p "$HOME/Library/LaunchAgents" "$APP_SUPPORT_DIR" "$STATE_DIR"

# spoofdpi kontrol / kurulum
if ! command -v spoofdpi >/dev/null 2>&1; then
  set +e
  brew list spoofdpi >/dev/null 2>&1 || brew install spoofdpi
  BREW_RC=$?
  set -e
  if [[ $BREW_RC -eq 0 ]]; then
    touch "$STATE_DIR/.installed_spoofdpi_via_brew"
  else
    echo "spoofdpi Homebrew ile otomatik kurulamadı. Lütfen elle kurun: brew install spoofdpi" >&2
  fi
fi

# plist + script
cp "$PLIST_SRC_DIR/$PLIST_FILE" "$TARGET_PLIST"
cp "$SCRIPT_SRC_DIR/$SCRIPT_FILE" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"

# Discord proxy'li launcher
cp "$PLIST_SRC_DIR/$LAUNCHER_PLIST_FILE" "$TARGET_LAUNCHER_PLIST"

# launchd yenile
launchctl unload "$TARGET_PLIST" 2>/dev/null || true
launchctl load -w "$TARGET_PLIST"
launchctl unload "$TARGET_LAUNCHER_PLIST" 2>/dev/null || true
launchctl load -w "$TARGET_LAUNCHER_PLIST"

echo "Kurulum tamam. Loglar: $HOME/Library/Logs/net.consolaktif.discord.spoofdpi.*.log"
echo "Discord otomatik olarak proxy'yi kullanacak; diğer uygulamalar etkilenmeyecek."