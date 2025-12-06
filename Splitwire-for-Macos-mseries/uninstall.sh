#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Kaldırma${RST}"; hr; }
info() { echo "${YLW}➜${RST} $*"; }
success() { echo "${GRN}✔${RST} $*"; }

title

echo "Bu işlem SplitWire'ı kaldıracak ve Discord'u orijinal haline getirecektir."
read -p "Devam? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "İptal."
    exit 0
fi

# Servisi durdur
info "Servis durduruluyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
success "Servis durduruldu"

# Discord'u orijinal haline getir
info "Discord orijinal haline getiriliyor..."

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
BACKUP_PLIST="$APP_SUPPORT_DIR/Info.plist.backup"
DISCORD_PLIST="/Applications/Discord.app/Contents/Info.plist"

if [ -f "$BACKUP_PLIST" ]; then
    cp "$BACKUP_PLIST" "$DISCORD_PLIST"
    codesign --force --deep --sign - /Applications/Discord.app 2>/dev/null || true
    success "Discord Info.plist orijinal haline getirildi"
else
    # Yedek yoksa, LSEnvironment'ı manuel kaldır
    if [ -f "$DISCORD_PLIST" ]; then
        python3 << PYEOF || true
import plistlib

plist_path = "$DISCORD_PLIST"
try:
    with open(plist_path, 'rb') as f:
        plist = plistlib.load(f)
    if 'LSEnvironment' in plist:
        del plist['LSEnvironment']
        with open(plist_path, 'wb') as f:
            plistlib.dump(plist, f)
        print("  -> LSEnvironment kaldırıldı")
except Exception as e:
    print(f"  -> Hata: {e}")
PYEOF
        codesign --force --deep --sign - /Applications/Discord.app 2>/dev/null || true
    fi
fi

# Eski wrapper varsa temizle
if [ -d "/Applications/Discord_Original.app" ]; then
    rm -rf "/Applications/Discord.app" 2>/dev/null || true
    mv "/Applications/Discord_Original.app" "/Applications/Discord.app"
    success "Wrapper kaldırıldı, orijinal Discord geri yüklendi"
fi

# SplitWire Discord varsa sil
rm -rf "/Applications/SplitWire Discord.app" 2>/dev/null || true

# Dosyaları temizle
info "Dosyalar siliniyor..."
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
rm -rf "$APP_SUPPORT_DIR"
rm -rf "$HOME/Library/Logs/ConsolAktifSplitWireLog"
rm -f "$HOME/Desktop/SplitWire Kontrol"
rm -f "$HOME/Desktop/SplitWire Loglar"
success "Dosyalar temizlendi"

# spoofdpi kaldırma
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
echo "Discord orijinal haline getirildi."
echo