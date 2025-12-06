#!/usr/bin/env bash
set -euo pipefail

echo "SplitWire Kaldırma (Intel)"
read -p "Kaldır? (y/N): " c
[[ ! "$c" =~ ^[Yy]$ ]] && exit 0

launchctl bootout gui/$(id -u)/net.consolaktif.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/Consolaktif-Discord"
rm -rf "$HOME/Library/Logs/SplitWire"
rm -rf "/Applications/SplitWire Discord.app"

echo "Kaldırıldı."

command -v brew &>/dev/null && brew list spoofdpi &>/dev/null && {
    read -p "spoofdpi kaldır? (y/N): " s
    [[ "$s" =~ ^[Yy]$ ]] && brew uninstall spoofdpi
}

echo "Tamamlandı."