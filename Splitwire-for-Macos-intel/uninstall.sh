#!/usr/bin/env bash
set -euo pipefail

# Renk tanımları
GRN=$(tput setaf 2 2>/dev/null || echo ""); YLW=$(tput setaf 3 2>/dev/null || echo ""); RED=$(tput setaf 1 2>/dev/null || echo ""); RST=$(tput sgr0 2>/dev/null || echo "")

# Başlık Fonksiyonu
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Kaldırma Aracı (Intel)${RST}"; hr; }
info() { echo "${YLW}➜${RST} $*"; }
success() { echo "${GRN}✔${RST} $*"; }

title

# 1. Kullanıcı Onayı
echo "Bu işlem SplitWire'ı ve tüm yapılandırma dosyalarını silecektir."
echo "Discord orijinal haline geri döndürülecektir."
echo
read -p "Devam etmek istiyor musunuz? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "İşlem iptal edildi."
    exit 0
fi

# Değişkenler
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"

PLIST_SPOOFDPI="net.consolaktif.discord.spoofdpi"
PLIST_LAUNCHER="net.consolaktif.discord.launcher"

# 2. Servisleri Durdurma
info "Servisler durduruluyor..."

launchctl bootout gui/$(id -u)/$PLIST_SPOOFDPI 2>/dev/null || true
launchctl bootout gui/$(id -u)/$PLIST_LAUNCHER 2>/dev/null || true

if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI.plist" ]; then
    launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI.plist" 2>/dev/null || true
fi
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER.plist" ]; then
    launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER.plist" 2>/dev/null || true
fi

pkill -x spoofdpi 2>/dev/null || true
pkill -x Discord 2>/dev/null || true
success "Servisler durduruldu."

# 3. Discord'u Orijinal Haline Geri Döndürme
info "Discord orijinal haline döndürülüyor..."

DISCORD_APP="/Applications/Discord.app"
DISCORD_ORIGINAL="/Applications/Discord_Original.app"

if [ -d "$DISCORD_ORIGINAL" ]; then
    if [ -f "$DISCORD_APP/Contents/Resources/splitwire_marker" ]; then
        rm -rf "$DISCORD_APP"
        success "SplitWire wrapper silindi."
    fi
    
    mv "$DISCORD_ORIGINAL" "$DISCORD_APP"
    success "Orijinal Discord geri yüklendi."
else
    # Eski yöntem: Binary değiştirilmişse geri al
    DISCORD_BIN="$DISCORD_APP/Contents/MacOS/Discord"
    ORIGINAL_BIN="$DISCORD_APP/Contents/MacOS/Discord_Original"
    
    if [ -f "$ORIGINAL_BIN" ]; then
        rm -f "$DISCORD_BIN"
        mv "$ORIGINAL_BIN" "$DISCORD_BIN"
        success "Discord binary geri yüklendi."
    fi
fi

# 4. Dosyaları Temizleme
info "Dosyalar siliniyor..."

rm -f "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI.plist"
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER.plist"
rm -rf "$APP_SUPPORT_DIR"
rm -rf "$LOG_DIR"
rm -f "$HOME/Desktop/SplitWire Kontrol"
rm -f "$HOME/Desktop/SplitWire Loglar"

success "Tüm uygulama dosyaları ve kısayollar temizlendi."

# 5. SpoofDPI Kaldırma (Opsiyonel)
echo
info "SplitWire, 'spoofdpi' aracını kullanır."
if command -v brew >/dev/null 2>&1; then
    if brew list spoofdpi &>/dev/null; then
        read -p "Homebrew ile kurulan 'spoofdpi' paketini de kaldırmak ister misiniz? (y/N): " remove_spoof
        if [[ "$remove_spoof" =~ ^[Yy]$ ]]; then
            brew uninstall spoofdpi
            success "'spoofdpi' başarıyla kaldırıldı."
        else
            echo "ℹ️ 'spoofdpi' sistemde bırakıldı."
        fi
    fi
fi

# 6. Bitiş
echo
hr
echo "${GRN}SplitWire başarıyla bilgisayarınızdan kaldırıldı.${RST}"
echo "Discord'u artık normal şekilde kullanabilirsiniz."
echo