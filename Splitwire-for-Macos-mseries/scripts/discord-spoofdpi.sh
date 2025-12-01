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
PORT_FILE="$APP_SUPPORT_DIR/.proxy_port"
mkdir -p "$APP_SUPPORT_DIR"

# ----------------------------------------------------------------
# PORT AYARI
# Hata riskini azaltmak için 8080'e sabitliyoruz.
# ----------------------------------------------------------------
CHOSEN_PORT="8080"
echo "$CHOSEN_PORT" > "$PORT_FILE"

# Loglama
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"

LISTEN_HOST="127.0.0.1"

echo "Başlatılıyor: Port $CHOSEN_PORT (DoH Aktif)"

# Varsa eskileri kapat
pkill -x spoofdpi || true

# ----------------------------------------------------------------
# DÜZELTME BURADA: Parametre isimleri güncellendi
# -port  -> -listen-port
# -addr  -> -listen-addr
# ----------------------------------------------------------------
exec "$SPOOF_BIN" \
  -listen-addr "$LISTEN_HOST" \
  -listen-port "$CHOSEN_PORT" \
  -enable-doh \
  -window-size 0