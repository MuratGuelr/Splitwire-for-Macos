#!/usr/bin/env bash
set -euo pipefail

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LOG_DIR="$HOME/Library/Logs"
LOCK_FILE="$APP_SUPPORT_DIR/.spoofdpi.lock"

mkdir -p "$APP_SUPPORT_DIR" "$LOG_DIR"

# Log rotate (10 MB)
rotate_log() {
  local log="$1" max=10485760
  [[ -f $log && $(stat -f%z "$log") -gt $max ]] && gzip -f "$log" && mv "$log.gz" "${log%.log}-$(date +%F-%H-%M).log.gz"
}
rotate_log "$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
rotate_log "$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"

find_spoofdpi() {
  if command -v spoofdpi >/dev/null 2>&1; then
    command -v spoofdpi
    return 0
  fi
  if [ -x "/opt/homebrew/bin/spoofdpi" ]; then
    echo "/opt/homebrew/bin/spoofdpi"
    return 0
  fi
  if [ -x "/usr/local/bin/spoofdpi" ]; then
    echo "/usr/local/bin/spoofdpi"
    return 0
  fi
  return 1
}

SPOOF_BIN="$(find_spoofdpi || true)"
if [ -z "${SPOOF_BIN:-}" ]; then
  echo "spoofdpi bulunamadı. Önce kurun: brew install spoofdpi" >&2
  exit 1
fi

# flock (çift başlatma önler)
exec 200>"$LOCK_FILE.flock"
flock -n 200 || { echo "spoofdpi zaten çalışıyor"; exit 0; }

cleanup() {
  rm -f "$LOCK_FILE" "$LOCK_FILE.flock" || true
}
trap cleanup EXIT INT TERM

echo $$ > "$LOCK_FILE"

LISTEN_HOST="127.0.0.1"
LISTEN_PORT="${CD_PROXY_PORT:-8080}"

# YENİ PARAMETRELER (eski -listen yok)
SPOOFDPI_ARGS=(
  -addr "$LISTEN_HOST"
  -port "$LISTEN_PORT"
)

echo "spoofdpi başlatılıyor: $SPOOF_BIN ${SPOOFDPI_ARGS[*]}"

# Çökme durumunda yeniden başlat
while true; do
  "$SPOOF_BIN" "${SPOOFDPI_ARGS[@]}" \
    >> "$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log" \
    2>> "$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"
  EXIT_CODE=$?
  echo "spoofdpi çıkış kodu ${EXIT_CODE}, 3 saniye sonra yeniden başlatılıyor..." >> "$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
  sleep 3
done