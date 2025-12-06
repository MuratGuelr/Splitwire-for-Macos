#!/usr/bin/env bash
set -euo pipefail

GRN=$'\e[32m'; YLW=$'\e[33m'; RED=$'\e[31m'; RST=$'\e[0m'
line() { echo "${YLW}────────────────────────────────────────────────────────${RST}"; }

echo
line
echo "${RED}SplitWire Kaldırma${RST}"
line
echo

read -p "SplitWire'ı kaldırmak istiyor musunuz? (y/N): " c
[[ ! "$c" =~ ^[Yy]$ ]] && echo "İptal." && exit 0

echo "Kaldırılıyor..."

# Servis durdur
launchctl bootout gui/$(id -u)/net.consolaktif.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

# Dosyaları sil
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/Consolaktif-Discord"
rm -rf "$HOME/Library/Logs/SplitWire"
rm -rf "/Applications/SplitWire Discord.app"

echo "${GRN}✓${RST} SplitWire kaldırıldı"

# spoofdpi
if command -v brew &>/dev/null && brew list spoofdpi &>/dev/null; then
    read -p "spoofdpi'yi de kaldır? (y/N): " s
    [[ "$s" =~ ^[Yy]$ ]] && brew uninstall spoofdpi && echo "${GRN}✓${RST} spoofdpi kaldırıldı"
fi

echo
line
echo "${GRN}Tamamlandı.${RST} Discord normal şekilde kullanılabilir."
echo