#!/bin/bash

# 1. Terminal Penceresini Gizle
osascript -e 'tell application "Terminal" to set visible of front window to false'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONTROL_SCRIPT_PATH="$SCRIPT_DIR/control.sh"

# Durumu kontrol et
CURRENT_STATUS=$("$CONTROL_SCRIPT_PATH" status)

if [ "$CURRENT_STATUS" == "Aktif" ]; then
    ICON="caution"
    STATUS_MSG="DURUM: 🟢 AKTİF"
    MSG_TEXT="SplitWire çalışıyor. Discord proxy üzerinden bağlı."
    BTN_MAIN="Durdur"
    BTN_SEC="Yeniden Başlat"
    BTN_CANCEL="Çıkış"
else
    ICON="note"
    STATUS_MSG="DURUM: 🔴 PASİF"
    MSG_TEXT="SplitWire kapalı. Discord normal bağlantı kullanıyor."
    BTN_MAIN="Başlat"
    BTN_SEC="Logları Aç"
    BTN_CANCEL="Çıkış"
fi

# Modern Diyalog Kutusu
USER_CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set theResult to display dialog "$MSG_TEXT" & return & return & "$STATUS_MSG" with title "SplitWire Kontrol Paneli" buttons {"$BTN_CANCEL", "$BTN_SEC", "$BTN_MAIN"} default button "$BTN_MAIN" with icon $ICON
    return button returned of theResult
end tell
EOF
)

case "$USER_CHOICE" in
    "Başlat")
        "$CONTROL_SCRIPT_PATH" start
        osascript -e 'display notification "SplitWire başlatıldı." with title "SplitWire"'
        ;;
    "Durdur")
        "$CONTROL_SCRIPT_PATH" stop
        osascript -e 'display notification "SplitWire durduruldu." with title "SplitWire"'
        ;;
    "Yeniden Başlat")
        "$CONTROL_SCRIPT_PATH" stop
        sleep 1
        "$CONTROL_SCRIPT_PATH" start
        osascript -e 'display notification "Servisler yeniden başlatıldı." with title "SplitWire"'
        ;;
    "Logları Aç")
        LOG_CMD="$SCRIPT_DIR/SplitWire Loglar.command"
        if [ -f "$LOG_CMD" ]; then open "$LOG_CMD"; else osascript -e 'display alert "Log aracı bulunamadı."'; fi
        ;;
    *) ;;
esac

# Pencereyi kapat ve çık
osascript -e 'tell application "Terminal" to close (first window whose visible is false)' &> /dev/null
exit 0