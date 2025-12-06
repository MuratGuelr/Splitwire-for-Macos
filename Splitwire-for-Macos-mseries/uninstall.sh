#!/usr/bin/env bash
set -euo pipefail

GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
info() { echo "${YLW}➜${RST} $*"; }
success() { echo "${GRN}✔${RST} $*"; }

hr; echo "${RED}SplitWire • Kaldırma${RST}"; hr

echo "Bu işlem SplitWire'ı kaldıracak."
echo "~/Applications/Discord.app normal haline getirilecek."
echo
read -p "Devam? (y/N): " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0

# Servisi durdur
info "Servis durduruluyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
pkill -x Discord 2>/dev/null || true
success "Servis durduruldu"

# Discord'u orijinal haline getir
info "Discord orijinal haline getiriliyor..."

APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
USER_DISCORD="$HOME/Applications/Discord.app"
BACKUP_PLIST="$APP_SUPPORT_DIR/Info.plist.backup"
DISCORD_PLIST="$USER_DISCORD/Contents/Info.plist"

if [ -f "$BACKUP_PLIST" ] && [ -d "$USER_DISCORD" ]; then
    cp "$BACKUP_PLIST" "$DISCORD_PLIST"
    codesign --force --deep --sign - "$USER_DISCORD" 2>/dev/null || true
    success "Discord Info.plist geri yüklendi"
fi

# Dosyaları temizle
info "Dosyalar siliniyor..."
rm -f "$HOME/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist"
rm -rf "$APP_SUPPORT_DIR"
rm -rf "$HOME/Library/Logs/ConsolAktifSplitWireLog"
success "Dosyalar temizlendi"

# ~/Applications/Discord.app'ı silmek ister misin?
echo
read -p "~/Applications/Discord.app'ı da silmek ister misiniz? (y/N): " del_discord
if [[ "$del_discord" =~ ^[Yy]$ ]]; then
    rm -rf "$USER_DISCORD"
    success "~/Applications/Discord.app silindi"
    echo "Artık /Applications/Discord.app'ı kullanabilirsiniz."
fi

# spoofdpi kaldırma
if command -v brew >/dev/null 2>&1 && brew list spoofdpi &>/dev/null; then
    read -p "spoofdpi'yi de kaldır? (y/N): " r
    [[ "$r" =~ ^[Yy]$ ]] && brew uninstall spoofdpi && success "spoofdpi kaldırıldı"
fi

hr
echo "${GRN}SplitWire kaldırıldı.${RST}"
echo