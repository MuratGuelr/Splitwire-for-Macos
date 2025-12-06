#!/bin/bash
# =============================================================================
# SplitWire Kontrol Paneli GUI - macOS 26 Uyumlu (Intel)
# =============================================================================

# Terminal Penceresini Gizle
osascript -e 'tell application "Terminal" to set visible of front window to false' 2>/dev/null || true

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONTROL_SCRIPT_PATH="$SCRIPT_DIR/control.sh"

# Durumu kontrol et
CURRENT_STATUS=$("$CONTROL_SCRIPT_PATH" status 2>/dev/null || echo "Pasif")

# spoofdpi PID'ini al
SPOOFDPI_PID=$(pgrep -x "spoofdpi" 2>/dev/null || echo "")

if [ "$CURRENT_STATUS" == "Aktif" ]; then
    ICON="caution"
    STATUS_MSG="DURUM: 🟢 AKTİF"
    if [ -n "$SPOOFDPI_PID" ]; then
        MSG_TEXT="SplitWire çalışıyor (PID: $SPOOFDPI_PID)

Discord proxy üzerinden bağlı.
Proxy: http://127.0.0.1:8080"
    else
        MSG_TEXT="SplitWire çalışıyor.
Discord proxy üzerinden bağlı."
    fi
    BTN_MAIN="Durdur"
    BTN_SEC="Yeniden Başlat"
    BTN_CANCEL="Çıkış"
else
    ICON="note"
    STATUS_MSG="DURUM: 🔴 PASİF"
    MSG_TEXT="SplitWire kapalı.

Discord normal bağlantı kullanıyor.
Proxy aktif etmek için 'Başlat' butonuna basın."
    BTN_MAIN="Başlat"
    BTN_SEC="Sistem Bilgisi"
    BTN_CANCEL="Çıkış"
fi

# Modern Diyalog Kutusu
USER_CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set theResult to display dialog "$MSG_TEXT" & return & return & "$STATUS_MSG" with title "SplitWire Kontrol Paneli v2.0 (Intel)" buttons {"$BTN_CANCEL", "$BTN_SEC", "$BTN_MAIN"} default button "$BTN_MAIN" with icon $ICON
    return button returned of theResult
end tell
EOF
)

case "$USER_CHOICE" in
    "Başlat")
        "$CONTROL_SCRIPT_PATH" start
        osascript -e 'display notification "SplitWire başlatıldı. Discord artık proxy kullanıyor." with title "SplitWire" sound name "Glass"'
        ;;
    "Durdur")
        "$CONTROL_SCRIPT_PATH" stop
        osascript -e 'display notification "SplitWire durduruldu. Discord normal bağlantı kullanacak." with title "SplitWire" sound name "Basso"'
        ;;
    "Yeniden Başlat")
        "$CONTROL_SCRIPT_PATH" restart
        osascript -e 'display notification "Servisler yeniden başlatıldı." with title "SplitWire" sound name "Glass"'
        ;;
    "Sistem Bilgisi")
        INFO=$("$CONTROL_SCRIPT_PATH" info 2>&1)
        osascript <<EOF
tell application "System Events"
    activate
    display dialog "$INFO" with title "SplitWire Sistem Bilgisi" buttons {"Tamam"} default button "Tamam" with icon note
end tell
EOF
        ;;
    "Logları Aç")
        LOG_CMD="$SCRIPT_DIR/SplitWire Loglar.command"
        if [ -f "$LOG_CMD" ]; then 
            open "$LOG_CMD"
        else 
            osascript -e 'display alert "Log aracı bulunamadı."'
        fi
        ;;
    *) ;;
esac

# Pencereyi kapat ve çık
osascript -e 'tell application "Terminal" to close (first window whose visible is false)' &>/dev/null || true
exit 0