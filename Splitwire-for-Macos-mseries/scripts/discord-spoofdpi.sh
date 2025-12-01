#!/usr/bin/env bash
set -euo pipefail

# Yardımcı Fonksiyon: SpoofDPI bul
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

# Dizin tanımları
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
PORT_FILE="$APP_SUPPORT_DIR/.proxy_port"
mkdir -p "$APP_SUPPORT_DIR"

# ----------------------------------------------------------------
# PORT SEÇİMİ
# ----------------------------------------------------------------
DEFAULT_PORT="${CD_PROXY_PORT:-8080}"
CHOSEN_PORT="$DEFAULT_PORT"

# Port 8080'den 8099'a kadar boş port ara
for p in $(seq 8080 8099); do
  if ! nc -z 127.0.0.1 $p >/dev/null 2>&1; then
    CHOSEN_PORT="$p"
    break
  fi
done

echo "$CHOSEN_PORT" > "$PORT_FILE"

# Loglama
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"

# Log Rotasyonu
rotate_if_large() {
  local file="$1"
  local limit=$((10*1024*1024))
  if [ -f "$file" ]; then
    local size=$(wc -c < "$file" 2>/dev/null | xargs)
    if [ "$size" -gt "$limit" ]; then
      mv "$file" "${file}.$(date +%s).gz"
      gzip "${file}.$(date +%s).gz" 2>/dev/null || true
    fi
  fi
}
rotate_if_large "$OUT_LOG"
rotate_if_large "$ERR_LOG"

LISTEN_HOST="127.0.0.1"

echo "Başlatılıyor: Port $CHOSEN_PORT (DoH Aktif)"

# ----------------------------------------------------------------
# DÜZELTME BURADA: macOS Sequoia ve TR Engeli İçin Parametreler
# -enable-doh: DNS engellemesini aşmak için (Zorunlu)
# -window-size 0: macOS ağ yığınında paketlerin daha rahat geçmesi için
# ----------------------------------------------------------------
exec "$SPOOF_BIN" \
  -addr "$LISTEN_HOST" \
  -port "$CHOSEN_PORT" \
  -enable-doh \
  -window-size 0