#!/bin/bash
# =============================================================================
# SplitWire Kontrol Paneli GUI
# =============================================================================
# Modern macOS diyalog kutusu ile servis kontrolü
# =============================================================================

# Terminal Penceresini Gizle
osascript -e 'tell application "Terminal" to set visible of front window to false' 2>/dev/null || true

# spoofdpi yolu
SPOOFDPI=""
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done

# Servis kontrol fonksiyonları
start_service() {
    launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null
    launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    sleep 2
}

stop_service() {
    launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    pkill -x spoofdpi 2>/dev/null
    sleep 1
}

restart_service() {
    stop_service
    sleep 1
    start_service
}

get_info() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "         SplitWire Sistem Bilgisi"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if pgrep -x spoofdpi > /dev/null 2>&1; then
        echo "🟢 spoofdpi: Çalışıyor (PID: $(pgrep -x spoofdpi))"
    else
        echo "🔴 spoofdpi: Durdu"
    fi
    
    if nc -z 127.0.0.1 8080 2>/dev/null; then
        echo "🟢 Port 8080: Açık"
    else
        echo "🔴 Port 8080: Kapalı"
    fi
    
    if launchctl list 2>/dev/null | grep -q "com.splitwire.spoofdpi"; then
        echo "🟢 LaunchAgent: Yüklü"
    else
        echo "🔴 LaunchAgent: Yüklü Değil"
    fi
    
    if pgrep -x Discord > /dev/null 2>&1; then
        echo "🟢 Discord: Çalışıyor"
    else
        echo "⚪ Discord: Kapalı"
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Döngü - menü
while true; do
    # Durumu kontrol et
    if pgrep -x spoofdpi > /dev/null 2>&1; then
        SPOOFDPI_PID=$(pgrep -x spoofdpi)
        STATUS_ICON="🟢"
        STATUS_TEXT="AKTİF"
        MSG_TEXT="SplitWire çalışıyor (PID: $SPOOFDPI_PID)

Discord proxy üzerinden bağlı.
Sistem proxy aktif.

Discord'u normal şekilde açabilirsiniz."
        BTN_MAIN="Durdur"
        BTN_SEC="Yeniden Başlat"
        ICON="caution"
    else
        STATUS_ICON="🔴"
        STATUS_TEXT="PASİF"
        MSG_TEXT="SplitWire kapalı.

Discord normal bağlantı kullanıyor.
Proxy aktif etmek için 'Başlat' butonuna basın."
        BTN_MAIN="Başlat"
        BTN_SEC="Sistem Bilgisi"
        ICON="note"
    fi

    # Diyalog göster
    USER_CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set theResult to display dialog "$MSG_TEXT" & return & return & "DURUM: $STATUS_ICON $STATUS_TEXT" with title "SplitWire Kontrol Paneli" buttons {"Çıkış", "$BTN_SEC", "$BTN_MAIN"} default button "$BTN_MAIN" with icon $ICON
    return button returned of theResult
end tell
EOF
    ) 2>/dev/null

    # İptal veya boş seçim
    if [ -z "$USER_CHOICE" ]; then
        break
    fi

    case "$USER_CHOICE" in
        "Başlat")
            start_service
            if pgrep -x spoofdpi > /dev/null; then
                osascript -e 'display notification "SplitWire başlatıldı. Proxy aktif." with title "SplitWire" sound name "Glass"'
            else
                osascript -e 'display notification "Başlatma başarısız!" with title "SplitWire" sound name "Basso"'
            fi
            ;;
        "Durdur")
            stop_service
            osascript -e 'display notification "SplitWire durduruldu. Proxy devre dışı." with title "SplitWire" sound name "Basso"'
            ;;
        "Yeniden Başlat")
            restart_service
            osascript -e 'display notification "Servis yeniden başlatıldı." with title "SplitWire" sound name "Glass"'
            ;;
        "Sistem Bilgisi")
            INFO=$(get_info)
            osascript <<EOF
tell application "System Events"
    activate
    display dialog "$INFO" with title "SplitWire Sistem Bilgisi" buttons {"Tamam"} default button "Tamam" with icon note
end tell
EOF
            ;;
        "Çıkış")
            break
            ;;
    esac
done

# Terminal penceresini kapat
osascript -e 'tell application "Terminal" to close (first window whose visible is false)' 2>/dev/null || true
exit 0