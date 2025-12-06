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

info "Discord orijinal haline getiriliyor..."
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
BACKUP="$APP_SUPPORT_DIR/Info.plist.backup"
PLIST="/Applications/Discord.app/Contents/Info.plist"

if [ -f "$BACKUP" ]; then
    cp "$BACKUP" "$PLIST"
    codesign --force --deep --sign - /Applications/Discord.app 2>/dev/null || true
    success "Discord geri yüklendi"
else
    python3 << PYEOF || true
import plistlib
try:
    with open("$PLIST", 'rb') as f: plist = plistlib.load(f)
    if 'LSEnvironment' in plist:
        del plist['LSEnvironment']
        with open("$PLIST", 'wb') as f: plistlib.dump(plist, f)
except: pass
PYEOF
    codesign --force --deep --sign - /Applications/Discord.app 2>/dev/null || true
fi

[ -d "/Applications/Discord_Original.app" ] && rm -rf "/Applications/Discord.app" && mv "/Applications/Discord_Original.app" "/Applications/Discord.app"
rm -rf "/Applications/SplitWire Discord.app" 2>/dev/null || true

info "Dosyalar siliniyor..."
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
rm -rf "$APP_SUPPORT_DIR"
rm -rf "$HOME/Library/Logs/ConsolAktifSplitWireLog"

if command -v brew >/dev/null 2>&1 && brew list spoofdpi &>/dev/null; then
    read -p "spoofdpi kaldır? (y/N): " r
    [[ "$r" =~ ^[Yy]$ ]] && brew uninstall spoofdpi
fi

hr
echo "${GRN}SplitWire kaldırıldı.${RST}"
echo