#!/bin/bash
# =============================================================================
# SplitWire Kontrol Paneli GUI (Intel)
# =============================================================================

osascript -e 'tell application "Terminal" to set visible of front window to false' 2>/dev/null || true

SPOOFDPI=""
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && SPOOFDPI="$p" && break
done

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
restart_service() { stop_service; sleep 1; start_service; }

get_info() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "         SplitWire Sistem Bilgisi"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    pgrep -x spoofdpi > /dev/null && echo "🟢 spoofdpi: Çalışıyor (PID: $(pgrep -x spoofdpi))" || echo "🔴 spoofdpi: Durdu"
    nc -z 127.0.0.1 8080 2>/dev/null && echo "🟢 Port 8080: Açık" || echo "🔴 Port 8080: Kapalı"
    launchctl list 2>/dev/null | grep -q "com.splitwire.spoofdpi" && echo "🟢 LaunchAgent: Yüklü" || echo "🔴 LaunchAgent: Yüklü Değil"
    pgrep -x Discord > /dev/null && echo "🟢 Discord: Çalışıyor" || echo "⚪ Discord: Kapalı"
    echo ""
}

while true; do
    if pgrep -x spoofdpi > /dev/null 2>&1; then
        PID=$(pgrep -x spoofdpi)
        MSG="SplitWire çalışıyor (PID: $PID)

Discord proxy üzerinden bağlı."
        BTN_MAIN="Durdur"; BTN_SEC="Yeniden Başlat"; ICON="caution"; STATUS="🟢 AKTİF"
    else
        MSG="SplitWire kapalı.

Proxy aktif etmek için 'Başlat' butonuna basın."
        BTN_MAIN="Başlat"; BTN_SEC="Sistem Bilgisi"; ICON="note"; STATUS="🔴 PASİF"
    fi

    CHOICE=$(osascript <<EOF
tell application "System Events"
    activate
    set theResult to display dialog "$MSG" & return & return & "DURUM: $STATUS" with title "SplitWire Kontrol Paneli" buttons {"Çıkış", "$BTN_SEC", "$BTN_MAIN"} default button "$BTN_MAIN" with icon $ICON
    return button returned of theResult
end tell
EOF
    ) 2>/dev/null

    [ -z "$CHOICE" ] && break

    case "$CHOICE" in
        "Başlat") start_service; pgrep -x spoofdpi > /dev/null && osascript -e 'display notification "Başlatıldı" with title "SplitWire" sound name "Glass"' ;;
        "Durdur") stop_service; osascript -e 'display notification "Durduruldu" with title "SplitWire" sound name "Basso"' ;;
        "Yeniden Başlat") restart_service; osascript -e 'display notification "Yeniden başlatıldı" with title "SplitWire" sound name "Glass"' ;;
        "Sistem Bilgisi") INFO=$(get_info); osascript -e "tell application \"System Events\" to display dialog \"$INFO\" with title \"Sistem Bilgisi\" buttons {\"Tamam\"} with icon note" ;;
        "Çıkış") break ;;
    esac
done

osascript -e 'tell application "Terminal" to close (first window whose visible is false)' 2>/dev/null || true
exit 0