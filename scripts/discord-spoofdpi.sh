#!/usr/bin/env bash
set -euo pipefail

find_spoofdpi() {
  local paths=( "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi" )
  for path in "${paths[@]}"; do
    [ -x "$path" ] && { echo "$path"; return 0; }
  done
  command -v spoofdpi
}

SPOOF_BIN=$(find_spoofdpi)
if [ -z "${SPOOF_BIN}" ]; then
  echo "HATA: spoofdpi çalıştırılabilir dosyası bulunamadı." >&2
  exit 1
fi

LISTEN_HOST="127.0.0.1"
LISTEN_PORT="${CD_PROXY_PORT:-8080}"
echo "spoofdpi başlatılıyor: $SPOOF_BIN -addr $LISTEN_HOST -port $LISTEN_PORT"
exec "$SPOOF_BIN" -addr "$LISTEN_HOST" -port "$LISTEN_PORT"