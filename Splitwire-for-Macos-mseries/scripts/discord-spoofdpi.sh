#!/usr/bin/env bash
set -euo pipefail

find_spoofdpi() {
  local paths=( "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi" "$HOME/.spoofdpi/bin/spoofdpi" )
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

# Port Sabitleme
CHOSEN_PORT="8080"
echo "$CHOSEN_PORT" > "$APP_SUPPORT_DIR/.proxy_port"

LISTEN_HOST="127.0.0.1"

# Çakışmayı önle
pkill -x spoofdpi || true

# ----------------------------------------------------------------
# DÜZELTME: Senin versiyonuna uygun ÇİFT TİRE (--) kullanımı
# ----------------------------------------------------------------
exec "$SPOOF_BIN" \
  --listen-addr "$LISTEN_HOST" \
  --listen-port "$CHOSEN_PORT" \
  --enable-doh \
  --window-size 0