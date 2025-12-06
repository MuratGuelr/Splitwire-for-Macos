#!/usr/bin/env bash
# SplitWire Kurulum (Intel) - macOS Native GUI
set -e

echo "SplitWire Kurulum (Intel)"

BREW=""
[ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
[ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
[ -z "$BREW" ] && echo "Homebrew yok!" && exit 1

eval "$($BREW shellenv)"
command -v spoofdpi &>/dev/null || $BREW install spoofdpi
SPOOFDPI_PATH=$(command -v spoofdpi)
echo "✓ spoofdpi"

[ ! -d "/Applications/Discord.app" ] && echo "Discord yok!" && exit 1
echo "✓ Discord"

SUPPORT_DIR="$HOME/Library/Application Support/SplitWire"
AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/SplitWire"
mkdir -p "$SUPPORT_DIR" "$AGENTS_DIR" "$LOG_DIR"

launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

cat > "$SUPPORT_DIR/run-spoofdpi.sh" << SCRIPT
#!/bin/bash
exec "$SPOOFDPI_PATH" --system-proxy 2>&1
SCRIPT
chmod +x "$SUPPORT_DIR/run-spoofdpi.sh"

cat > "$AGENTS_DIR/com.splitwire.spoofdpi.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.splitwire.spoofdpi</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SUPPORT_DIR/run-spoofdpi.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/spoofdpi.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/spoofdpi.log</string>
</dict>
</plist>
PLIST

launchctl load -w "$AGENTS_DIR/com.splitwire.spoofdpi.plist"
sleep 2

cat > "$HOME/Desktop/SplitWire.command" << 'PANEL'
#!/bin/bash
get_status() {
    pgrep -x spoofdpi > /dev/null 2>&1 && echo "✅ Çalışıyor (PID: $(pgrep -x spoofdpi))" || echo "❌ Durdu"
}
show_notification() {
    osascript -e "display notification \"$1\" with title \"SplitWire\" sound name \"Pop\""
}
start_service() {
    launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null
    launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    sleep 2
    pgrep -x spoofdpi > /dev/null && show_notification "Başlatıldı" || show_notification "Başlatılamadı!"
}
stop_service() {
    launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    pkill -x spoofdpi 2>/dev/null
    sleep 1
    show_notification "Durduruldu"
}
restart_service() { stop_service; sleep 1; start_service; }
open_discord() { open -a Discord; show_notification "Discord açıldı"; }
show_logs() {
    LOG=~/Library/Logs/SplitWire/spoofdpi.log
    [ -f "$LOG" ] && osascript -e "display dialog \"$(tail -30 $LOG 2>/dev/null)\" with title \"Loglar\" buttons {\"Tamam\"}" || osascript -e 'display alert "Log yok"'
}

while true; do
    STATUS=$(get_status)
    CHOICE=$(osascript -e "
        button returned of (display dialog \"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          SplitWire Kontrol Paneli
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Durum: $STATUS

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\" with title \"SplitWire\" buttons {\"Çıkış\", \"Loglar\", \"Discord Aç\", \"Yeniden Başlat\", \"Durdur\", \"Başlat\"} default button \"Discord Aç\" with icon note)
    " 2>/dev/null)
    case "$CHOICE" in
        "Başlat") start_service;; "Durdur") stop_service;; "Yeniden Başlat") restart_service;;
        "Discord Aç") open_discord;; "Loglar") show_logs;; *) exit 0;;
    esac
done
PANEL
chmod +x "$HOME/Desktop/SplitWire.command"

echo ""
echo "✅ Kurulum tamamlandı!"
echo "Masaüstündeki 'SplitWire.command' ile kontrol edin."