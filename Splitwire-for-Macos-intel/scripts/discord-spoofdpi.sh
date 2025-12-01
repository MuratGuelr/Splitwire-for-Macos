#!/usr/bin/env bash
set -euo pipefail

find_spoofdpi() {
  local paths=( "/usr/local/bin/spoofdpi" "/opt/homebrew/bin/spoofdpi" "$HOME/.spoofdpi/bin/spoofdpi" )
  for path in "${paths[@]}"; do
    if [ -x "$path" ]; then echo "$path"; return 0; fi
  done
  command -v spoofdpi
}

SPOOF_BIN=$(find_spoofdpi)
if [ -z "${SPOOF_BIN}" ]; then
  echo "HATA: spoofdpi bulunamadı." >&2
  exit 1
fi

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
mkdir -p "$APP_SUPPORT_DIR"
echo "8080" > "$APP_SUPPORT_DIR/.proxy_port"

LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"

# Eski processleri temizle
pkill -x spoofdpi || true

echo "SpoofDPI (Intel) Başlatılıyor..."

exec "$SPOOF_BIN" \
  --listen-addr 127.0.0.1 \
  --listen-port 8080 \
  --enable-doh \
  --window-size 0