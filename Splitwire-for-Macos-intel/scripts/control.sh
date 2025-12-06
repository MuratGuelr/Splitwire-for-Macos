#!/bin/bash
# =============================================================================
# SplitWire Kontrol Scripti - macOS 26 Uyumlu (Intel)
# =============================================================================
set -euo pipefail

SPOOFDPI_LABEL="net.consolaktif.discord.spoofdpi"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_SPOOFDPI="$LAUNCH_AGENTS_DIR/$SPOOFDPI_LABEL.plist"

start_services() {
    echo "Servisler başlatılıyor..."
    
    # Önce varsa eski servisi kaldır
    launchctl bootout gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
    pkill -x spoofdpi 2>/dev/null || true
    sleep 1
    
    # Servisi yükle ve başlat
    if [ -f "$PLIST_SPOOFDPI" ]; then
        launchctl load -w "$PLIST_SPOOFDPI" 2>/dev/null || true
        sleep 1
        launchctl kickstart -k gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
        echo "Servis tetiklendi."
    else
        echo "HATA: Plist dosyası bulunamadı: $PLIST_SPOOFDPI"
        return 1
    fi
}

stop_services() {
    echo "Servisler durduruluyor..."
    launchctl bootout gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
    pkill -x spoofdpi 2>/dev/null || true
    pkill -x Discord 2>/dev/null || true
    echo "Servisler durduruldu."
}

restart_services() {
    echo "Servisler yeniden başlatılıyor..."
    stop_services
    sleep 2
    start_services
}

check_status() {
    # Process çalışıyor mu kontrol et
    if pgrep -x "spoofdpi" >/dev/null 2>&1; then
        echo "Aktif"
    else
        echo "Pasif"
    fi
}

show_info() {
    echo "=== SplitWire Durum Bilgisi (Intel) ==="
    echo
    
    # spoofdpi durumu
    if pgrep -x "spoofdpi" >/dev/null 2>&1; then
        echo "🟢 spoofdpi: Çalışıyor (PID: $(pgrep -x spoofdpi))"
        
        # Port kontrolü
        if nc -z 127.0.0.1 8080 2>/dev/null; then
            echo "🟢 Port 8080: Dinleniyor"
        else
            echo "🟡 Port 8080: Kontrol edilemedi"
        fi
    else
        echo "🔴 spoofdpi: Çalışmıyor"
    fi
    
    # Discord durumu
    if pgrep -x "Discord" >/dev/null 2>&1; then
        echo "🟢 Discord: Çalışıyor"
    else
        echo "⚪ Discord: Kapalı"
    fi
    
    # LaunchAgent durumu
    if launchctl list 2>/dev/null | grep -q "$SPOOFDPI_LABEL"; then
        echo "🟢 LaunchAgent: Yüklü"
    else
        echo "🔴 LaunchAgent: Yüklü değil"
    fi
    
    echo
}

case "${1:-}" in
    start) start_services ;;
    stop) stop_services ;;
    restart) restart_services ;;
    status) check_status ;;
    info) show_info ;;
    *) echo "Kullanım: $0 {start|stop|restart|status|info}"; exit 1 ;;
esac