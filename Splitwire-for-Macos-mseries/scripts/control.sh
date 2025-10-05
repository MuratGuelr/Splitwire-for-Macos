#!/bin/bash
set -euo pipefail

SPOOFDPI_LABEL="net.consolaktif.discord.spoofdpi"
LAUNCHER_LABEL="net.consolaktif.discord.launcher"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_SPOOFDPI="$LAUNCH_AGENTS_DIR/$SPOOFDPI_LABEL.plist"
PLIST_LAUNCHER="$LAUNCH_AGENTS_DIR/$LAUNCHER_LABEL.plist"

start_services() {
    echo "Servisler başlatılıyor..."
    # 1. Servis tanımlarını launchd'ye yükle (spoofdpi'ın çalışmasını sağlar)
    launchctl load -w "$PLIST_SPOOFDPI" 2>/dev/null || true
    launchctl load -w "$PLIST_LAUNCHER" 2>/dev/null || true

    # 2. Mevcut, belki de proxy'siz çalışan Discord'u kapat
    echo "Mevcut Discord kapatılıyor..."
    pkill -x Discord || true
    sleep 1 # Prosesin tam olarak sonlanması için kısa bir bekleme

    # 3. Proxy servisinin aktif olmasını bekle (En Önemli Adım)
    echo "Proxy servisinin başlaması bekleniyor..."
    i=0
    while ! lsof -i :${CD_PROXY_PORT:-8080} &>/dev/null; do
        sleep 0.5
        i=$((i+1))
        if [ "$i" -ge 20 ]; then # 10 saniyelik zaman aşımı
            echo "HATA: Proxy servisi 10 saniye içinde başlayamadı."
            osascript -e 'display notification "Proxy servisi başlatılamadı. Logları kontrol edin." with title "SplitWire Hatası"'
            exit 1
        fi
    done
    echo "Proxy servisi aktif. Discord başlatılıyor..."

    # 4. Discord'u doğrudan ve güvenilir bir şekilde başlat
    nohup /Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:${CD_PROXY_PORT:-8080}" &>/dev/null &
    
    echo "Başlatma isteği gönderildi. Discord birkaç saniye içinde açılacak."
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
    # spoofdpi servisinin yüklü olup olmadığını kontrol et
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