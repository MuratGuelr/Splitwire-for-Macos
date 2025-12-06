#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Kaldırma (Intel)${RST}"; hr; }
info() { echo "${YLW}➜${RST} $*"; }
success() { echo "${GRN}✔${RST} $*"; }

title

echo "Bu işlem SplitWire'ı kaldıracaktır."
read -p "Devam? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "İptal."
    exit 0
fi

info "Servis durduruluyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
success "Servis durduruldu"

info "Dosyalar siliniyor..."
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
rm -rf "$HOME/Library/Application Support/Consolaktif-Discord"
rm -rf "$HOME/Library/Logs/ConsolAktifSplitWireLog"
rm -f "$HOME/Desktop/SplitWire Kontrol"
rm -f "$HOME/Desktop/SplitWire Loglar"

if [ -d "/Applications/SplitWire Discord.app" ]; then
    rm -rf "/Applications/SplitWire Discord.app"
    success "SplitWire Discord.app silindi"
fi

if [ -d "/Applications/Discord_Original.app" ]; then
    rm -rf "/Applications/Discord.app" 2>/dev/null || true
    mv "/Applications/Discord_Original.app" "/Applications/Discord.app"
    success "Orijinal Discord geri yüklendi"
fi

success "Tüm dosyalar temizlendi"

if command -v brew >/dev/null 2>&1 && brew list spoofdpi &>/dev/null; then
    read -p "spoofdpi'yi de kaldır? (y/N): " remove_spoof
    if [[ "$remove_spoof" =~ ^[Yy]$ ]]; then
        brew uninstall spoofdpi
        success "spoofdpi kaldırıldı"
    fi
fi

echo
hr
echo "${GRN}SplitWire kaldırıldı.${RST}"
echo