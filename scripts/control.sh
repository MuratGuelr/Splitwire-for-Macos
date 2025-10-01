#!/bin/bash
set -euo pipefail

SPOOFDPI_LABEL="net.consolaktif.discord.spoofdpi"
LAUNCHER_LABEL="net.consolaktif.discord.launcher"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_SPOOFDPI="$LAUNCH_AGENTS_DIR/$SPOOFDPI_LABEL.plist"
PLIST_LAUNCHER="$LAUNCH_AGENTS_DIR/$LAUNCHER_LABEL.plist"

start_services() {
    echo "Servisler başlatılıyor..."
    launchctl load -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl load -w "$PLIST_LAUNCHER" 2>/dev/null || true
    launchctl start "$LAUNCHER_LABEL"
    echo "Başlatma isteği gönderildi. Discord birkaç saniye içinde açılacak."
}

stop_services() {
    echo "Servisler durduruluyor..."
    launchctl unload -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl unload -w "$PLIST_LAUNCHER" 2>/dev/null || true
    pkill -x Discord || true
    echo "Servisler durduruldu ve Discord kapatıldı."
}

check_status() {
    if launchctl list | grep -q "$SPOOFDPI_LABEL"; then
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