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

# Loglama
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"

# Eski processleri temizle
pkill -x spoofdpi || true

echo "SpoofDPI Başlatılıyor..."

# --listen-addr 127.0.0.1 : IPv4 zorlar
# --enable-doh : DNS engelini aşar
# --window-size 0 : Paket boyutunu manipüle eder (Türkiye için genelde gereklidir)
exec "$SPOOF_BIN" \
  --listen-addr 127.0.0.1 \
  --listen-port 8080 \
  --enable-doh \
  --window-size 0