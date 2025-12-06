#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
info() { echo "${YLW}➜${RST} $*"; }
success() { echo "${GRN}✔${RST} $*"; }

hr; echo "${RED}SplitWire • Kaldırma (Intel)${RST}"; hr

read -p "SplitWire'ı kaldır? (y/N): " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0

info "Servis durduruluyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
pkill -x Discord 2>/dev/null || true

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
USER_DISCORD="$HOME/Applications/Discord.app"
BACKUP="$APP_SUPPORT_DIR/Info.plist.backup"

if [ -f "$BACKUP" ] && [ -d "$USER_DISCORD" ]; then
    cp "$BACKUP" "$USER_DISCORD/Contents/Info.plist"
    codesign --force --deep --sign - "$USER_DISCORD" 2>/dev/null || true
    success "Discord geri yüklendi"
fi

info "Dosyalar siliniyor..."
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
rm -rf "$APP_SUPPORT_DIR"
rm -rf "$HOME/Library/Logs/ConsolAktifSplitWireLog"

read -p "~/Applications/Discord.app sil? (y/N): " d
[[ "$d" =~ ^[Yy]$ ]] && rm -rf "$USER_DISCORD" && success "Silindi"

if command -v brew >/dev/null 2>&1 && brew list spoofdpi &>/dev/null; then
    read -p "spoofdpi kaldır? (y/N): " r
    [[ "$r" =~ ^[Yy]$ ]] && brew uninstall spoofdpi
fi

hr; echo "${GRN}SplitWire kaldırıldı.${RST}"; echo