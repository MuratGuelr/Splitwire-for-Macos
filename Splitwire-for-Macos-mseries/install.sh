#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti - Tüm macOS Sürümleri İçin
# =============================================================================
# Bu script Discord'u spoofdpi proxy ile çalışacak şekilde yapılandırır.
# Discord herhangi bir yerden (Dock, Spotlight, Finder) açılsa bile
# proxy üzerinden çalışır. spoofdpi arka planda sürekli çalışır ve
# sorun olursa otomatik yeniden başlatılır.
#
# NOT: Bu yöntem Discord binary'sini DEĞİŞTİRMEZ. Bunun yerine:
#   1. Orijinal Discord.app -> Discord_Original.app olarak taşınır
#   2. Yerine bir AppleScript uygulaması konur
#   3. Bu uygulama Discord'u proxy ile başlatır
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
title() { hr; echo "${GRN}SplitWire • Entegrasyon Kurulumu${RST}"; hr; }

# ----------------------------------------------------------------------
# İKON DEĞİŞTİRME FONKSİYONU
# ----------------------------------------------------------------------
set_icon() {
    local icon_path="$1"
    local target_file="$2"
    
    if [ ! -f "$icon_path" ] || [ ! -e "$target_file" ]; then return 0; fi

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
    touch "$target_file" 2>/dev/null || true
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

cp "$SCRIPT_DIR/scripts/discord-spoofdpi.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/control.sh" "$APP_SUPPORT_DIR/"
cp "$SCRIPT_DIR/scripts/SplitWire Kontrol.command" "$APP_SUPPORT_DIR/" 2>/dev/null || true
cp "$SCRIPT_DIR/scripts/SplitWire Loglar.command" "$APP_SUPPORT_DIR/" 2>/dev/null || true

chmod +x "$APP_SUPPORT_DIR"/*.sh 2>/dev/null || true
chmod +x "$APP_SUPPORT_DIR"/*.command 2>/dev/null || true
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
# DISCORD ENTEGRASYONU (AppleScript Wrapper - Binary Değiştirmeden)
# ----------------------------------------------------------------------
echo "Discord uygulaması yapılandırılıyor..."

DISCORD_APP="/Applications/Discord.app"
DISCORD_ORIGINAL="/Applications/Discord_Original.app"

if [ ! -d "$DISCORD_APP" ] && [ ! -d "$DISCORD_ORIGINAL" ]; then
    error "Discord.app /Applications klasöründe bulunamadı!"
    echo "Lütfen önce 'install-discord.sh' komutunu çalıştırın."
    exit 1
fi

# Eğer orijinal Discord varsa ve wrapper yoksa, taşı
if [ -d "$DISCORD_APP" ] && [ ! -d "$DISCORD_ORIGINAL" ]; then
    # Bu gerçek Discord mu yoksa bizim wrapper mı kontrol et
    if [ -f "$DISCORD_APP/Contents/MacOS/Discord" ] && [ ! -f "$DISCORD_APP/Contents/Resources/splitwire_marker" ]; then
        echo "  -> Orijinal Discord yedekleniyor..."
        mv "$DISCORD_APP" "$DISCORD_ORIGINAL"
    fi
fi

# AppleScript Wrapper Uygulaması Oluştur
echo "  -> Wrapper uygulama oluşturuluyor..."

WRAPPER_APP="$DISCORD_APP"
WRAPPER_CONTENTS="$WRAPPER_APP/Contents"
WRAPPER_MACOS="$WRAPPER_CONTENTS/MacOS"
WRAPPER_RESOURCES="$WRAPPER_CONTENTS/Resources"

# Wrapper app yapısını oluştur
rm -rf "$WRAPPER_APP" 2>/dev/null || true
mkdir -p "$WRAPPER_MACOS" "$WRAPPER_RESOURCES"

# Info.plist oluştur
cat > "$WRAPPER_CONTENTS/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Discord</string>
    <key>CFBundleIconFile</key>
    <string>electron</string>
    <key>CFBundleIdentifier</key>
    <string>com.hnc.Discord</string>
    <key>CFBundleName</key>
    <string>Discord</string>
    <key>CFBundleDisplayName</key>
    <string>Discord</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
</dict>
</plist>
PLIST_EOF

# Başlatıcı script oluştur
cat > "$WRAPPER_MACOS/Discord" << 'LAUNCHER_EOF'
#!/bin/bash
# =============================================================================
# SplitWire Discord Başlatıcı
# =============================================================================

# Update Döngüsü Temizliği
rm -rf "$HOME/Library/Application Support/discord/pending" 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/discord/modules/pending" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.hnc.Discord.ShipIt" 2>/dev/null || true

# PATH ayarı
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Orijinal Discord yolu
ORIGINAL_APP="/Applications/Discord_Original.app"
if [ ! -d "$ORIGINAL_APP" ]; then
    osascript -e 'display alert "Hata" message "Discord_Original.app bulunamadı. Lütfen SplitWire kurulumunu tekrar çalıştırın."'
    exit 1
fi

# spoofdpi çalışmıyorsa başlatmayı dene
if ! pgrep -x "spoofdpi" > /dev/null 2>&1; then
    launchctl kickstart gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
fi

# Proxy hazır olana kadar bekle (maksimum 10 saniye)
PROXY_READY=false
for i in $(seq 1 10); do
    if nc -z 127.0.0.1 8080 2>/dev/null; then
        PROXY_READY=true
        break
    fi
    sleep 1
done

# Proxy hazır değilse Discord'u AÇMA
if [ "$PROXY_READY" != true ]; then
    osascript -e 'display alert "SplitWire Hatası" message "spoofdpi proxy başlatılamadı. Discord açılamıyor.\n\nÇözüm için:\n1. SplitWire Kontrol panelinden servisi başlatın\n2. Veya Terminal'\''de: launchctl kickstart gui/$(id -u)/net.consolaktif.discord.spoofdpi" buttons {"Tamam"} default button "Tamam"'
    exit 1
fi

# Proxy hazır - Discord'u proxy ile başlat
export http_proxy="http://127.0.0.1:8080"
export https_proxy="http://127.0.0.1:8080"
export all_proxy="http://127.0.0.1:8080"
exec "$ORIGINAL_APP/Contents/MacOS/Discord" --proxy-server="http://127.0.0.1:8080" "$@"
LAUNCHER_EOF

chmod +x "$WRAPPER_MACOS/Discord"

# İkonu orijinalden kopyala
if [ -d "$DISCORD_ORIGINAL" ]; then
    ORIGINAL_ICON="$DISCORD_ORIGINAL/Contents/Resources/electron.icns"
    if [ -f "$ORIGINAL_ICON" ]; then
        cp "$ORIGINAL_ICON" "$WRAPPER_RESOURCES/"
    fi
fi

# SplitWire marker dosyası oluştur (bu bizim wrapper olduğunu belirtir)
touch "$WRAPPER_RESOURCES/splitwire_marker"

# quarantine temizle
xattr -cr "$WRAPPER_APP" 2>/dev/null || true

checkmark "Discord wrapper uygulaması oluşturuldu."

# Settings.json Ayarı - Otomatik güncellemeleri atla
SETTINGS_FILE="$HOME/Library/Application Support/discord/settings.json"
SETTINGS_DIR="$(dirname "$SETTINGS_FILE")"

if [ -d "$SETTINGS_DIR" ]; then
    if [ ! -f "$SETTINGS_FILE" ]; then
        echo '{"SKIP_HOST_UPDATE": true}' > "$SETTINGS_FILE"
    else
        if ! grep -q "SKIP_HOST_UPDATE" "$SETTINGS_FILE"; then
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

DISCORD_ICON="$DISCORD_ORIGINAL/Contents/Resources/electron.icns"
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
echo "📂 ${YLW}DOSYA YAPISI:${RST}"
echo "   • /Applications/Discord.app       -> SplitWire Wrapper (açılacak uygulama)"
echo "   • /Applications/Discord_Original.app -> Gerçek Discord (dokunmayın)"
echo
echo "🔧 ${YLW}KONTROL:${RST}"
echo "   • Masaüstünden 'SplitWire Kontrol' ile servisi yönetebilirsiniz"
echo "   • Logları görmek için 'SplitWire Loglar' kullanın"
echo
echo "⚠️  ${YLW}NOT:${RST} Discord güncellenirse bu işlemi tekrar yapmanız gerekebilir."
echo