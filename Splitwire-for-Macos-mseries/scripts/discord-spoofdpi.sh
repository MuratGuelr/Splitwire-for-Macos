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

# Sabit Port Kullanalım (Sorun gidermek için otomatikten vazgeçip 8080'e sabitleyelim)
CHOSEN_PORT="8080"
echo "$CHOSEN_PORT" > "$PORT_FILE"

# Loglama
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"

LISTEN_HOST="127.0.0.1"

echo "Başlatılıyor: Port $CHOSEN_PORT (DoH Aktif)"

# Eğer önceki spoofdpi çalışıyorsa kapat
pkill -x spoofdpi || true

# KRİTİK: Sadece -enable-doh kullanıyoruz, window-size kaldırdık.
# Bazen window-size update sunucusunu bozabiliyor.
exec "$SPOOF_BIN" \
  -addr "$LISTEN_HOST" \
  -port "$CHOSEN_PORT" \
  -enable-doh