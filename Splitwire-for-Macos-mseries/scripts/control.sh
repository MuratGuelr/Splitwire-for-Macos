#!/bin/bash
set -euo pipefail

SPOOFDPI_LABEL="net.consolaktif.discord.spoofdpi"
LAUNCHER_LABEL="net.consolaktif.discord.launcher"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_SPOOFDPI="$LAUNCH_AGENTS_DIR/$SPOOFDPI_LABEL.plist"
PLIST_LAUNCHER="$LAUNCH_AGENTS_DIR/$LAUNCHER_LABEL.plist"

start_services() {
    echo "Servisler başlatılıyor..."
    
    # 1. Temiz bir başlangıç için önce unload yap
    launchctl unload -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl unload -w "$PLIST_LAUNCHER" 2>/dev/null || true

    # 2. Servisleri yükle
    launchctl load -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl load -w "$PLIST_LAUNCHER" 2>/dev/null || true

    # 3. macOS 15+ için Kickstart (Zorla tetikleme)
    # Bu komut servisin hemen çalışmasını garanti eder
    launchctl kickstart -k gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
    launchctl kickstart -k gui/$(id -u)/$LAUNCHER_LABEL 2>/dev/null || true

    echo "Başlatma komutu gönderildi. Discord açılıyor..."
}

stop_services() {
    echo "Servisler durduruluyor..."
    # Servisleri durdur ve launchd'den kaldır
    launchctl unload -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl unload -w "$PLIST_LAUNCHER" 2>/dev/null || true
    
    # Çalışan Discord uygulamasını kapat
    pkill -x Discord || true
    echo "Servisler durduruldu ve Discord kapatıldı."
}

check_status() {
    # Servisin yüklü olup olmadığını kontrol et
    if launchctl list | grep -q "$SPOOFDPI_LABEL"; then
        echo "Aktif"
    else
        echo "Pasif"
    fi
}

# Ana betik mantığı
case "${1:-}" in
    start) start_services ;;
    stop) stop_services ;;
    status) check_status ;;
    *) echo "Kullanım: $0 {start|stop|status}"; exit 1 ;;
esac