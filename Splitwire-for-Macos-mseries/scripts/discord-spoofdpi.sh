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

# Apple Silicon doğrulaması ve ikili mimarisi kontrolü
if [ "$(uname -m)" != "arm64" ]; then
  echo "HATA: Bu kurulum yalnızca Apple Silicon (arm64) içindir." >&2
  exit 1
fi

# spoofdpi ikilisinin arm64 olduğundan emin ol
if command -v file >/dev/null 2>&1; then
  if ! file "$SPOOF_BIN" | grep -qi "arm64"; then
    echo "HATA: spoofdpi arm64 değil. Lütfen ARM Homebrew ile yeniden kurun: 'brew uninstall spoofdpi && brew install spoofdpi'" >&2
    exit 1
  fi
fi

LISTEN_HOST="127.0.0.1"

# Uygulama destek dizini ve port dosyası
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
PORT_FILE="$APP_SUPPORT_DIR/.proxy_port"
mkdir -p "$APP_SUPPORT_DIR"

# Otomatik port seçimi: 8080..8099 arası uygun ilk port
DEFAULT_PORT="${CD_PROXY_PORT:-8080}"
CHOSEN_PORT=""
for p in $(seq 8080 8099); do
  if ! lsof -i :$p >/dev/null 2>&1; then
    CHOSEN_PORT="$p"
    break
  fi
done

if [ -z "$CHOSEN_PORT" ]; then
  CHOSEN_PORT="$DEFAULT_PORT"
fi

echo "$CHOSEN_PORT" > "$PORT_FILE"
timestamp() { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(timestamp)] [SplitWire] $*"; }

# Log dosyalarını döndür (10MB üstü ise gzip)
LOG_DIR="$HOME/Library/Logs"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"
rotate_if_large() {
  local file="$1"
  local limit=$((10*1024*1024))
  if [ -f "$file" ]; then
    local size=$(wc -c < "$file" 2>/dev/null || echo 0)
    if [ "$size" -ge "$limit" ]; then
      local ts=$(date '+%Y%m%d-%H%M%S')
      local rotated="${file}.${ts}"
      mv "$file" "$rotated" 2>/dev/null || true
      gzip -f "$rotated" 2>/dev/null || true
      log "Log döndürüldü: $(basename "$file") -> $(basename "$rotated").gz"
    fi
  fi
}

mkdir -p "$LOG_DIR"
rotate_if_large "$OUT_LOG"
rotate_if_large "$ERR_LOG"

# Toplam log boyutu eşiği (ör. 50 MB) geçerse kullanıcıyı uyar
total_log_bytes() {
  local sum=0
  for f in "$OUT_LOG" "$ERR_LOG" "$OUT_LOG".*.gz "$ERR_LOG".*.gz; do
    if [ -f "$f" ]; then
      local s=$(wc -c < "$f" 2>/dev/null || echo 0)
      sum=$((sum + s))
    fi
  done
  echo "$sum"
}

notify_if_huge_logs() {
  local threshold=$((50*1024*1024)) # 50MB
  local total=$(total_log_bytes)
  if [ "$total" -ge "$threshold" ]; then
    local mb=$((total/1024/1024))
    log "Toplam log boyutu yüksek: ${mb}MB"
    if command -v osascript >/dev/null 2>&1; then
      osascript -e 'display notification "SplitWire log boyutu yüksek. SplitWire Loglar ile temizleyin." with title "SplitWire Uyarı"'
    fi
  fi
}

notify_if_huge_logs

log "spoofdpi başlatılıyor: $SPOOF_BIN -addr $LISTEN_HOST -port $CHOSEN_PORT"
exec "$SPOOF_BIN" -addr "$LISTEN_HOST" -port "$CHOSEN_PORT"