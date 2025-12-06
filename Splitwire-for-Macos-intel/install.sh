#!/usr/bin/env bash
# SplitWire Kurulum (Intel)
set -e

echo "SplitWire Kurulum (Intel)"
echo ""

BREW=""
[ -x "/usr/local/bin/brew" ] && BREW="/usr/local/bin/brew"
[ -x "/opt/homebrew/bin/brew" ] && BREW="/opt/homebrew/bin/brew"
[ -z "$BREW" ] && echo "Homebrew yok!" && exit 1

eval "$($BREW shellenv)"
command -v spoofdpi &>/dev/null || $BREW install spoofdpi
SPOOFDPI_PATH=$(command -v spoofdpi)
echo "✓ spoofdpi: $SPOOFDPI_PATH"

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
pgrep -x spoofdpi > /dev/null && echo "✓ Servis çalışıyor" || echo "! Servis başlatılamadı"

cat > "$HOME/Desktop/SplitWire.command" << 'PANEL'
#!/bin/bash
clear
while true; do
    if pgrep -x spoofdpi > /dev/null 2>&1; then
        STATUS="✅ ÇALIŞIYOR"; PID=$(pgrep -x spoofdpi)
    else
        STATUS="❌ DURDU"; PID="-"
    fi
    clear
    echo ""
    echo "══════════════════════════════════════════"
    echo "  SplitWire Kontrol Paneli"
    echo "══════════════════════════════════════════"
    echo "  Durum: $STATUS  (PID: $PID)"
    echo "──────────────────────────────────────────"
    echo "  [1] Başlat  [2] Durdur  [3] Yeniden Başlat"
    echo "  [4] Discord Aç  [5] Loglar  [6] Çıkış"
    echo "──────────────────────────────────────────"
    read -p "  Seçim: " c
    case $c in
        1) launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null; launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null; sleep 2;;
        2) launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null; pkill -x spoofdpi 2>/dev/null; sleep 1;;
        3) launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null; pkill -x spoofdpi 2>/dev/null; sleep 1; launchctl load -w ~/Library/LaunchAgents/com.splitwire.spoofdpi.plist 2>/dev/null; sleep 2;;
        4) open -a Discord;;
        5) echo ""; tail -20 ~/Library/Logs/SplitWire/spoofdpi.log 2>/dev/null; read -p "Enter...";;
        6) exit 0;;
    esac
done
PANEL
chmod +x "$HOME/Desktop/SplitWire.command"

echo ""
echo "✅ Kurulum tamamlandı!"
echo "Masaüstündeki 'SplitWire.command' ile kontrol edebilirsiniz."
echo "Discord'u normal açabilirsiniz - otomatik proxy kullanır."