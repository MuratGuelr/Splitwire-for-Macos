#!/usr/bin/env bash
set -euo pipefail

# Mac mimarisini tespit et
ARCH=$(uname -m)
echo "Mac mimarisi tespit edildi: $ARCH"

# Homebrew kurulum yolunu tespit et
detect_homebrew_path() {
  if [ -x "/opt/homebrew/bin/brew" ]; then
    echo "/opt/homebrew"
  elif [ -x "/usr/local/bin/brew" ]; then
    echo "/usr/local"
  else
    echo ""
  fi
}

HOMEBREW_PREFIX=$(detect_homebrew_path)
if [ -z "$HOMEBREW_PREFIX" ]; then
  echo "HATA: Homebrew bulunamadı. Lütfen önce Homebrew kurun." >&2
  exit 1
fi

echo "Homebrew prefix: $HOMEBREW_PREFIX"

# spoofdpi binary'sini bul
find_spoofdpi() {
  local paths=(
    "$HOMEBREW_PREFIX/bin/spoofdpi"
    "/opt/homebrew/bin/spoofdpi"
    "/usr/local/bin/spoofdpi"
    "/usr/bin/spoofdpi"
  )
  
  for path in "${paths[@]}"; do
    if [ -x "$path" ]; then
      echo "spoofdpi bulundu: $path"
      echo "$path"
      return 0
    fi
  done
  
  # PATH'te ara
  if command -v spoofdpi >/dev/null 2>&1; then
    local cmd_path=$(command -v spoofdpi)
    echo "spoofdpi PATH'te bulundu: $cmd_path"
    echo "$cmd_path"
    return 0
  fi
  
  return 1
}

SPOOF_BIN=$(find_spoofdpi)
if [ -z "${SPOOF_BIN}" ]; then
  echo "HATA: spoofdpi çalıştırılabilir dosyası bulunamadı." >&2
  echo "Kontrol edilen yollar:" >&2
  echo "  - $HOMEBREW_PREFIX/bin/spoofdpi" >&2
  echo "  - /opt/homebrew/bin/spoofdpi" >&2
  echo "  - /usr/local/bin/spoofdpi" >&2
  echo "  - /usr/bin/spoofdpi" >&2
  echo "  - PATH içinde" >&2
  echo "" >&2
  echo "Çözüm önerileri:" >&2
  echo "  1. Homebrew ile spoofdpi kurun: brew install spoofdpi" >&2
  echo "  2. PATH'inizi kontrol edin: echo \$PATH" >&2
  echo "  3. Homebrew'u yeniden kurun: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"" >&2
  exit 1
fi

# Binary'nin çalışabilir olduğunu test et
if ! "$SPOOF_BIN" -h >/dev/null 2>&1; then
  echo "HATA: spoofdpi binary'si çalıştırılamıyor: $SPOOF_BIN" >&2
  echo "Binary dosyasını kontrol edin veya yeniden kurun." >&2
  exit 1
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
  # Hepsi doluysa, en azından DEFAULT_PORT'u deneyelim
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

log "spoofdpi başlatılıyor:"
log "  Binary: $SPOOF_BIN"
log "  Host: $LISTEN_HOST"
log "  Port: $CHOSEN_PORT"
log "  Mimari: $ARCH"

exec "$SPOOF_BIN" -addr "$LISTEN_HOST" -port "$CHOSEN_PORT"