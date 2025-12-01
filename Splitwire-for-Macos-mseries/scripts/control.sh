#!/bin/bash
set -euo pipefail

SPOOFDPI_LABEL="net.consolaktif.discord.spoofdpi"
LAUNCHER_LABEL="net.consolaktif.discord.launcher"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_SPOOFDPI="$LAUNCH_AGENTS_DIR/$SPOOFDPI_LABEL.plist"
PLIST_LAUNCHER="$LAUNCH_AGENTS_DIR/$LAUNCHER_LABEL.plist"

start_services() {
    echo "Servisler başlatılıyor..."
    
    # Temizlik
    launchctl bootout gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
    launchctl bootout gui/$(id -u)/$LAUNCHER_LABEL 2>/dev/null || true
    
    # Yükle
    launchctl load -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl load -w "$PLIST_LAUNCHER" 2>/dev/null || true

    # Başlat (Kickstart)
    launchctl kickstart -k gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
    launchctl kickstart -k gui/$(id -u)/$LAUNCHER_LABEL 2>/dev/null || true
    
    echo "Servisler tetiklendi."
}

stop_services() {
    echo "Servisler durduruluyor..."
    launchctl bootout gui/$(id -u)/$SPOOFDPI_LABEL 2>/dev/null || true
    launchctl bootout gui/$(id -u)/$LAUNCHER_LABEL 2>/dev/null || true
    pkill -x Discord || true
    pkill -x spoofdpi || true
}

check_status() {
    # DÜZELTME: Sadece lafına bakma, işlem gerçekten çalışıyor mu?
    if pgrep -x "spoofdpi" >/dev/null; then
        echo "Aktif"
    else
        echo "Pasif"
    fi
}

case "${1:-}" in
    start) start_services ;;
    stop) stop_services ;;
    status) check_status ;;
    *) echo "Kullanım: $0 {start|stop|status}"; exit 1 ;;
esac