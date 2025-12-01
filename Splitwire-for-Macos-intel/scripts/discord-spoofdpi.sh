#!/usr/bin/env bash
set -euo pipefail

# SpoofDPI bulucu (Intel ve M-Serisi uyumlu)
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

# Loglama Klasörü
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"

# Eski süreçleri temizle
pkill -x spoofdpi || true

echo "SpoofDPI Başlatılıyor (Port: 8080, DoH: Aktif)..."

# En kararlı parametreler
exec "$SPOOF_BIN" \
  --listen-addr 127.0.0.1 \
  --listen-port 8080 \
  --enable-doh \
  --window-size 0