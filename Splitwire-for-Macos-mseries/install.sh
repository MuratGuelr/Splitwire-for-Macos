#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti - macOS 26 (Tahoe) Uyumlu
# =============================================================================
# Bu script Discord'u spoofdpi proxy ile çalışacak şekilde yapılandırır.
# Discord herhangi bir yerden (Dock, Spotlight, Finder) açılsa bile
# proxy üzerinden çalışır. spoofdpi arka planda sürekli çalışır ve
# sorun olursa otomatik yeniden başlatılır.
# =============================================================================
set -euo pipefail

# ----------------------------------------------------------------------
# RENKLER VE YARDIMCI FONKSİYONLAR
# ----------------------------------------------------------------------
GRN=$(tput setaf 2 2>/dev/null || echo ""); YLW=$(tput setaf 3 2>/dev/null || echo ""); RED=$(tput setaf 1 2>/dev/null || echo ""); RST=$(tput sgr0 2>/dev/null || echo "")
checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • macOS 26 Uyumlu Entegrasyon Kurulumu${RST}"; hr; }

# ----------------------------------------------------------------------
# GÜÇLENDİRİLMİŞ İKON DEĞİŞTİRME FONKSİYONU
# ----------------------------------------------------------------------
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    
    if [ ! -f "$icon_path" ] || [ ! -f "$target_file" ]; then return 0; fi

    cat <<'EOF' > /tmp/seticon.swift
import Cocoa
let args = CommandLine.arguments
guard args.count == 3 else { exit(1) }
let iconPath = args[1]
let targetPath = args[2]

if let image = NSImage(contentsOfFile: iconPath) {
    let workspace = NSWorkspace.shared
    workspace.setIcon(image, forFile: targetPath, options: [])
}
EOF
    /usr/bin/swift /tmp/seticon.swift "$icon_path" "$target_file" >/dev/null 2>&1 || true
    rm -f /tmp/seticon.swift
    touch "$target_file" # Finder yenilemesi
}

title

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 1. Mimari ve Homebrew Yolu Tespiti
ARCH=$(uname -m)
if [ "$ARCH" == "arm64" ]; then
    HOMEBREW_PATH="/opt/homebrew"
else
    HOMEBREW_PATH="/usr/local"
fi

# 2. Klasör Yapıları
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"

mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ----------------------------------------------------------------------
# BAĞIMLILIK KONTROLLERİ
# ----------------------------------------------------------------------
echo "Bağımlılıklar kontrol ediliyor..."

# Xcode CLT Kontrol
if ! xcode-select -p >/dev/null 2>&1; then
    warning "Xcode CLT kuruluyor..."
    xcode-select --install || true
    echo "Xcode CLT kurulumunu tamamlayın ve bu scripti tekrar çalıştırın."
    exit 1
fi

# Homebrew Kontrol
if ! command -v brew >/dev/null 2>&1; then
    if [ -x "$HOMEBREW_PATH/bin/brew" ]; then
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
    else
        warning "Homebrew bulunamadı, kuruluyor..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
    fi
fi

# spoofdpi Kontrol
if ! brew list spoofdpi &>/dev/null; then
    warning "spoofdpi kuruluyor..."
    brew install spoofdpi
fi

# Binary yolunu garantiye al
SPOOFDPI_BIN=$(command -v spoofdpi 2>/dev/null || echo "$HOMEBREW_PATH/bin/spoofdpi")
if [ ! -x "$SPOOFDPI_BIN" ]; then
    error "spoofdpi binary dosyası bulunamadı. Lütfen 'brew install spoofdpi' komutunu manuel çalıştırın."
    exit 1
fi
checkmark "Tüm bağımlılıklar hazır (spoofdpi: $SPOOFDPI_BIN)"

# ----------------------------------------------------------------------
# MEVCUT SERVİSLERİ TEMİZLE
# ----------------------------------------------------------------------
echo "Eski servisler temizleniyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
launchctl bootout gui/$(id -u)/net.consolaktif.discord.launcher 2>/dev/null || true
launchctl unload ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist 2>/dev/null || true
launchctl unload ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist 2>/dev/null || true
rm -f ~/Library/LaunchAgents/net.consolaktif.discord.launcher.plist
pkill -x spoofdpi 2>/dev/null || true

# ----------------------------------------------------------------------
# SCRIPT DOSYALARINI KOPYALA
# ----------------------------------------------------------------------
echo "Script dosyaları kopyalanıyor..."

# discord-spoofdpi.sh kopyala
cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/"
chmod +x "$APP_SUPPORT_DIR/discord-spoofdpi.sh"

# control.sh kopyala
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
chmod +x "$APP_SUPPORT_DIR/control.sh"

# Kontrol ve Log araçlarını kopyala
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/" 2>/dev/null || true
chmod +x "$APP_SUPPORT_DIR"/*.command 2>/dev/null || true

# Quarantine temizliği
xattr -d com.apple.quarantine "$APP_SUPPORT_DIR"/* 2>/dev/null || true

checkmark "Script dosyaları hazır."

# ----------------------------------------------------------------------
# LAUNCHAGENT KURULUMU (SpoofDPI Arka Plan Servisi)
# ----------------------------------------------------------------------
echo "Proxy servisi yapılandırılıyor..."

TEMPLATE="$SCRIPT_DIR/launchd/net.consolaktif.discord.spoofdpi.plist.template"
TARGET="$LAUNCH_AGENTS_DIR/net.consolaktif.discord.spoofdpi.plist"

if [ -f "$TEMPLATE" ]; then
    sed "s|__USER_HOME__|$HOME|g" "$TEMPLATE" > "$TARGET"
else
    error "Launchd şablonu bulunamadı: $TEMPLATE"
    exit 1
fi

# Servisi yükle ve başlat
launchctl load -w "$TARGET"
sleep 1
launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true

# Servisin başladığını doğrula
sleep 2
if pgrep -x "spoofdpi" >/dev/null; then
    checkmark "Proxy servisi (spoofdpi) başlatıldı ve çalışıyor."
else
    warning "Proxy servisi henüz başlamadı, manuel kontrol gerekebilir."
fi

# ----------------------------------------------------------------------
# DISCORD ENTEGRASYONU (Wrapper + Code Signing)
# ----------------------------------------------------------------------
echo "Discord uygulaması modifiye ediliyor..."

DISCORD_APP="/Applications/Discord.app"
DISCORD_BIN="$DISCORD_APP/Contents/MacOS/Discord"
ORIGINAL_BIN="$DISCORD_APP/Contents/MacOS/Discord_Original"

if [ ! -d "$DISCORD_APP" ]; then
    error "Discord.app /Applications klasöründe bulunamadı!"
    echo "Lütfen önce 'install-discord.sh' komutunu çalıştırın."
    exit 1
fi

echo "${YLW}Lütfen şifrenizi girin (Discord dosyasını güncellemek ve imzalamak için):${RST}"
sudo -v

# Wrapper Script Oluştur - macOS 26 Uyumlu
cat <<'WRAPPER_EOF' > /tmp/Discord_Wrapper
#!/bin/bash
# =============================================================================
# SplitWire Discord Başlatıcı - macOS 26 Uyumlu
# =============================================================================
# Bu wrapper script Discord'u her zaman spoofdpi proxy üzerinden çalıştırır.
# =============================================================================

# Update Döngüsü Temizliği (Discord güncelleme hatalarını önler)
rm -rf "$HOME/Library/Application Support/discord/pending" 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/discord/modules/pending" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.hnc.Discord.ShipIt" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.hnc.Discord/ShipIt_stderr.log" 2>/dev/null || true

# Proxy Ayarları - Discord bu ortam değişkenlerini okuyacak
export http_proxy="http://127.0.0.1:8080"
export https_proxy="http://127.0.0.1:8080"
export all_proxy="http://127.0.0.1:8080"
export HTTP_PROXY="http://127.0.0.1:8080"
export HTTPS_PROXY="http://127.0.0.1:8080"
export ALL_PROXY="http://127.0.0.1:8080"

# PATH ayarı
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Bu script'in bulunduğu dizin
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# spoofdpi çalışmıyorsa LaunchAgent'ı tetikle
if ! pgrep -x "spoofdpi" > /dev/null 2>&1; then
    # LaunchAgent'ı kickstart ile başlat
    launchctl kickstart -k gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
    
    # Proxy hazır olana kadar bekle (maksimum 10 saniye)
    WAIT_COUNT=0
    while ! nc -z 127.0.0.1 8080 2>/dev/null; do
        sleep 0.5
        WAIT_COUNT=$((WAIT_COUNT + 1))
        if [ $WAIT_COUNT -ge 20 ]; then
            break
        fi
    done
fi

# Orijinal Discord'u proxy parametresiyle başlat
exec "$DIR/Discord_Original" --proxy-server="http://127.0.0.1:8080" --ignore-certificate-errors "$@"
WRAPPER_EOF

# Dosya Değişimi ve İmzalama
sudo bash -c "
    if [ ! -f '$ORIGINAL_BIN' ]; then
        echo '  -> Orijinal dosya yedekleniyor...'
        mv '$DISCORD_BIN' '$ORIGINAL_BIN'
    fi
    
    echo '  -> Wrapper script yerleştiriliyor...'
    cp /tmp/Discord_Wrapper '$DISCORD_BIN'
    chmod +x '$DISCORD_BIN'
    
    echo '  -> Uygulama yeniden imzalanıyor (Ad-hoc)...'
    # macOS 26 için --options=runtime eklendi
    codesign --force --deep --sign - --options=runtime '$DISCORD_APP' 2>/dev/null || codesign --force --deep --sign - '$DISCORD_APP'
"
rm /tmp/Discord_Wrapper

checkmark "Discord başarıyla yamalandı ve imzalandı."

# Settings.json Ayarı - Otomatik güncellemeleri atla
SETTINGS_FILE="$HOME/Library/Application Support/discord/settings.json"
SETTINGS_DIR="$(dirname "$SETTINGS_FILE")"

if [ -d "$SETTINGS_DIR" ]; then
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{"SKIP_HOST_UPDATE": true}' > "$SETTINGS_FILE"
    else
        if ! grep -q "SKIP_HOST_UPDATE" "$SETTINGS_FILE"; then
            # JSON'a ayar ekle
            if command -v python3 >/dev/null 2>&1; then
                python3 -c "
import json
try:
    with open('$SETTINGS_FILE', 'r') as f:
        data = json.load(f)
    data['SKIP_HOST_UPDATE'] = True
    with open('$SETTINGS_FILE', 'w') as f:
        json.dump(data, f, indent=2)
except:
    pass
" 2>/dev/null || true
            fi
        fi
    fi
    checkmark "Discord ayarları güncellendi."
fi

# ----------------------------------------------------------------------
# MASAÜSTÜ KISAYOLLARI VE İKONLAR
# ----------------------------------------------------------------------
echo "Masaüstü kısayolları oluşturuluyor..."

DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
CONSOLE_ICON="/System/Applications/Utilities/Console.app/Contents/Resources/AppIcon.icns"

# Kontrol Kısayolu
DESKTOP_CTRL="$HOME/Desktop/SplitWire Kontrol"
rm -f "$DESKTOP_CTRL"
ln -s "$APP_SUPPORT_DIR/SplitWire Kontrol.command" "$DESKTOP_CTRL" 2>/dev/null || true

# Loglar Kısayolu
DESKTOP_LOGS="$HOME/Desktop/SplitWire Loglar"
if [ -f "$APP_SUPPORT_DIR/SplitWire Loglar.command" ]; then
    rm -f "$DESKTOP_LOGS"
    ln -s "$APP_SUPPORT_DIR/SplitWire Loglar.command" "$DESKTOP_LOGS" 2>/dev/null || true
fi

# İkonları Uygula
echo "  -> İkonlar güncelleniyor..."
if [ -f "$DISCORD_ICON" ]; then
    set_icon "$DISCORD_ICON" "$APP_SUPPORT_DIR/SplitWire Kontrol.command"
    set_icon "$DISCORD_ICON" "$DESKTOP_CTRL"
fi
if [ -f "$CONSOLE_ICON" ] && [ -L "$DESKTOP_LOGS" ]; then
    set_icon "$CONSOLE_ICON" "$APP_SUPPORT_DIR/SplitWire Loglar.command"
    set_icon "$CONSOLE_ICON" "$DESKTOP_LOGS"
fi

checkmark "Masaüstü kısayolları hazır."

# ----------------------------------------------------------------------
# KURULUM TAMAMLANDI
# ----------------------------------------------------------------------
echo
hr
echo "${GRN}✅ ENTEGRASYON KURULUMU TAMAMLANDI!${RST}"
hr
echo
echo "📋 ${YLW}ÖZELLİKLER:${RST}"
echo "   1. ${GRN}spoofdpi${RST} arka planda sürekli çalışıyor (LaunchAgent)"
echo "   2. Discord her açıldığında (Dock/Spotlight/Finder) proxy kullanıyor"
echo "   3. Sorun olursa spoofdpi otomatik yeniden başlatılıyor"
echo "   4. ${YLW}Diğer uygulamalar etkilenmiyor${RST} - yalnızca Discord proxy kullanıyor"
echo
echo "🔧 ${YLW}KONTROL:${RST}"
echo "   • Masaüstünden 'SplitWire Kontrol' ile servisi yönetebilirsiniz"
echo "   • Logları görmek için 'SplitWire Loglar' kullanın"
echo
echo "⚠️  ${YLW}NOT:${RST} Discord güncellenirse bu işlemi tekrar yapmanız gerekebilir."
echo