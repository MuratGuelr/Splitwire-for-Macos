#!/usr/bin/env bash
# SplitWire Kurulum (Intel)
set -e

echo "SplitWire Kurulum (Intel)"
echo ""

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

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

cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$SUPPORT_DIR/"
chmod +x "$SUPPORT_DIR/SplitWire Kontrol.command"

ln -sf "$SUPPORT_DIR/SplitWire Kontrol.command" "$HOME/Desktop/SplitWire Kontrol"

echo ""
echo "✅ Kurulum tamamlandı!"
echo "Masaüstündeki 'SplitWire Kontrol' ile yönetin."