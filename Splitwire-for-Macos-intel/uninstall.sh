#!/usr/bin/env bash
echo "SplitWire kaldırılıyor..."
launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.splitwire.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/SplitWire"
rm -rf "$HOME/Library/Logs/SplitWire"
rm -f "$HOME/Desktop/SplitWire Kontrol"
echo "✓ Kaldırıldı"