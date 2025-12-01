#!/usr/bin/env bash
set -euo pipefail

# Renk tanımları
GRN=$(tput setaf 2); YLW=$(tput setaf 3); RED=$(tput setaf 1); RST=$(tput sgr0)

# Başlık Fonksiyonu
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${RED}SplitWire • Kaldırma Aracı${RST}"; hr; }
info() { echo "${YLW}➜${RST} $*"; }
success() { echo "${GRN}✔${RST} $*"; }

title

# 1. Kullanıcı Onayı
echo "Bu işlem SplitWire'ı ve tüm yapılandırma dosyalarını silecektir."
read -p "Devam etmek istiyor musunuz? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "İşlem iptal edildi."
    exit 0
fi

# Değişkenler (Dosya yolları)
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"

PLIST_SPOOFDPI="net.consolaktif.discord.spoofdpi"
PLIST_LAUNCHER="net.consolaktif.discord.launcher"

# 2. Servisleri Durdurma (macOS 15 Uyumlu)
section_start="Servisler durduruluyor..."
info "$section_start"

# Yeni yöntem (bootout) - Hata verirse yoksay
launchctl bootout gui/$(id -u)/$PLIST_SPOOFDPI 2>/dev/null || true
launchctl bootout gui/$(id -u)/$PLIST_LAUNCHER 2>/dev/null || true

# Eski yöntem (unload) - Garanti olsun diye
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI.plist" ]; then
    launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI.plist" 2>/dev/null || true
fi
if [ -f "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER.plist" ]; then
    launchctl unload -w "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER.plist" 2>/dev/null || true
fi

# Discord'u kapat (Proxy bağlantısını kesmek için)
pkill -x Discord 2>/dev/null || true
success "Servisler durduruldu ve Discord kapatıldı."

# 3. Dosyaları Temizleme
info "Dosyalar siliniyor..."

# Plist dosyaları
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_SPOOFDPI.plist"
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_LAUNCHER.plist"

# Uygulama Destek Klasörü (Scriptler ve ayarlar)
rm -rf "$APP_SUPPORT_DIR"

# Log Klasörü
rm -rf "$LOG_DIR"

# Masaüstü Kısayolları
rm -f "$HOME/Desktop/SplitWire Kontrol"
rm -f "$HOME/Desktop/SplitWire Loglar"

success "Tüm uygulama dosyaları ve kısayollar temizlendi."

# 4. SpoofDPI Kaldırma (Opsiyonel)
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

# 5. Bitiş
echo
hr
echo "${GRN}SplitWire başarıyla bilgisayarınızdan kaldırıldı.${RST}"
echo "Discord'u artık normal şekilde kullanabilirsiniz."
echo