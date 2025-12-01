#!/bin/bash

# 1. Terminali Gizle
osascript -e 'tell application "Terminal" to set visible of front window to false'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
OUT_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.out.log"
ERR_LOG="$LOG_DIR/net.consolaktif.discord.spoofdpi.err.log"

TARGET_LOG="$ERR_LOG"
if [ ! -s "$ERR_LOG" ]; then TARGET_LOG="$OUT_LOG"; fi

# Menü Seçimi
USER_CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set myList to {"🔍 Son Hataları Göster", "⚡ Canlı Log Takibi", "📂 Klasörü Aç", "🧹 Logları Temizle"}
    set theResult to choose from list myList with title "SplitWire Log Yöneticisi" with prompt "İşlem seçin:" default items {"🔍 Son Hataları Göster"} OK button name "Seç" cancel button name "İptal"
    if theResult is false then return "İptal"
    return item 1 of theResult
end tell
EOF
)

case "$USER_CHOICE" in
    "📂 Klasörü Aç")
        open "$LOG_DIR" ;;
        
    "🔍 Son Hataları Göster")
        if [ ! -f "$TARGET_LOG" ]; then
            osascript -e 'display alert "Log yok." message "Henüz log kaydı oluşmamış."'
        else
            TMP_FILE="/tmp/SplitWire_Son_Log.txt"
            tail -n 100 "$TARGET_LOG" | sed -E 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g' > "$TMP_FILE"
            open -a TextEdit "$TMP_FILE"
        fi ;;
        
    "⚡ Canlı Log Takibi")
        osascript <<END
tell application "Terminal"
    set newWindow to do script "clear; echo '--- SplitWire Canlı Log (Çıkış için pencereyi kapatın) ---'; tail -f \"$TARGET_LOG\""
    set custom title of newWindow to "SplitWire Live Logs"
    set background color of newWindow to {0, 0, 0}
    set normal text color of newWindow to {0, 65535, 0}
    activate
end tell
END
        ;;
        
    "🧹 Logları Temizle")
        rm -f "$LOG_DIR"/*.log "$LOG_DIR"/*.gz
        osascript -e 'display notification "Loglar temizlendi." with title "SplitWire"' ;;
esac

osascript -e 'tell application "Terminal" to close (first window whose visible is false)' &> /dev/null
exit 0