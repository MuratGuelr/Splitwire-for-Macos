#!/usr/bin/env bash
set -e

echo "SplitWire Kaldırma (Intel)"
read -p "Kaldır? (y/N): " c
[[ ! "$c" =~ ^[Yy]$ ]] && exit 0

launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.splitwire.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/SplitWire"
rm -rf "$HOME/Library/Logs/SplitWire"
rm -rf "/Applications/SplitWire Discord.app"

echo "✓ Kaldırıldı"

command -v brew &>/dev/null && brew list spoofdpi &>/dev/null && {
    read -p "spoofdpi kaldır? (y/N): " s
    [[ "$s" =~ ^[Yy]$ ]] && brew uninstall spoofdpi
}

echo "Tamamlandı."