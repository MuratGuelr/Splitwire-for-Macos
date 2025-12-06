#!/usr/bin/env bash
# =============================================================================
# SplitWire - SpoofDPI Servis Başlatıcı (macOS 26 Tahoe Uyumlu)
# =============================================================================
set -euo pipefail

# Sinyal yakalama - graceful shutdown
cleanup() {
    echo "[$(date)] Sinyal alındı, kapatılıyor..."
    pkill -x spoofdpi 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT SIGHUP

# SpoofDPI bulucu (Intel ve M-Serisi uyumlu)
find_spoofdpi() {
    local paths=(
        "/opt/homebrew/bin/spoofdpi"
        "/usr/local/bin/spoofdpi"
        "$HOME/.spoofdpi/bin/spoofdpi"
    )
    for path in "${paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    command -v spoofdpi 2>/dev/null || true
}

SPOOF_BIN=$(find_spoofdpi)
if [ -z "${SPOOF_BIN}" ] || [ ! -x "${SPOOF_BIN}" ]; then
    echo "HATA: spoofdpi bulunamadı." >&2
    exit 1
fi

# Loglama Klasörü
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$LOG_DIR"

# Port Yapılandırması
LISTEN_PORT="${SPOOFDPI_PORT:-8080}"
LISTEN_ADDR="127.0.0.1"

# Eski süreçleri temizle (port çakışmasını önle)
pkill -x spoofdpi 2>/dev/null || true
sleep 1

# Port kullanılabilirliğini kontrol et
check_port() {
    ! nc -z "$LISTEN_ADDR" "$LISTEN_PORT" 2>/dev/null
}

# Eğer port kullanılıyorsa alternatif port bul
if ! check_port; then
    echo "[$(date)] Port $LISTEN_PORT kullanımda, alternatif aranıyor..."
    for alt_port in $(seq 8081 8099); do
        LISTEN_PORT=$alt_port
        if check_port; then
            echo "[$(date)] Alternatif port bulundu: $LISTEN_PORT"
            break
        fi
    done
fi

echo "[$(date)] SpoofDPI Başlatılıyor..."
echo "  -> Binary: $SPOOF_BIN"
echo "  -> Adres: $LISTEN_ADDR:$LISTEN_PORT"
echo "  -> DoH: Aktif"

# spoofdpi'yi foreground'da çalıştır (LaunchAgent için gerekli)
# exec ile process'i değiştir - bu sayede launchd doğrudan spoofdpi'yi izler
exec "$SPOOF_BIN" \
    --listen-addr "$LISTEN_ADDR" \
    --listen-port "$LISTEN_PORT" \
    --enable-doh \
    --window-size 0