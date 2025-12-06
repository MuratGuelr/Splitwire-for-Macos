#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti
# =============================================================================
# Bu script Discord'u spoofdpi proxy ile çalıştıran ayrı bir uygulama oluşturur.
# Orijinal Discord.app'a HİÇ DOKUNMAZ.
#
# Kurulum sonrası:
#   /Applications/Discord.app          → Orijinal (normal kullanım)
#   /Applications/SplitWire Discord.app → Proxy ile açar (DPI bypass)
#
# Kullanıcı "SplitWire Discord" uygulamasını Dock'a ekleyebilir.
# =============================================================================
set -euo pipefail

# ----------------------------------------------------------------------
# RENKLER VE YARDIMCI FONKSİYONLAR
# ----------------------------------------------------------------------
GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }
title() { hr; echo "${GRN}SplitWire • Kurulum${RST}"; hr; }

title

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Mimari tespiti
ARCH=$(uname -m)
if [ "$ARCH" == "arm64" ]; then
    HOMEBREW_PATH="/opt/homebrew"
else
    HOMEBREW_PATH="/usr/local"
fi

# Klasörler
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"

mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ----------------------------------------------------------------------
# BAĞIMLILIK KONTROLLERİ
# ----------------------------------------------------------------------
echo "Bağımlılıklar kontrol ediliyor..."

# Homebrew
if ! command -v brew >/dev/null 2>&1; then
    if [ -x "$HOMEBREW_PATH/bin/brew" ]; then
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
    else
        warning "Homebrew bulunamadı, kuruluyor..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
    fi
fi
checkmark "Homebrew hazır"

# spoofdpi
if ! brew list spoofdpi &>/dev/null; then
    warning "spoofdpi kuruluyor..."
    brew install spoofdpi
fi

SPOOFDPI_BIN=$(command -v spoofdpi 2>/dev/null || echo "$HOMEBREW_PATH/bin/spoofdpi")
if [ ! -x "$SPOOFDPI_BIN" ]; then
    error "spoofdpi bulunamadı!"
    exit 1
fi
checkmark "spoofdpi hazır ($SPOOFDPI_BIN)"

# Discord kontrolü
if [ ! -d "/Applications/Discord.app" ]; then
    error "Discord.app bulunamadı! Önce Discord'u kurun."
    exit 1
fi
checkmark "Discord.app mevcut"

# ----------------------------------------------------------------------
# ESKİ KURULUMLARI TEMİZLE
# ----------------------------------------------------------------------
echo "Eski kurulumlar temizleniyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

# Eski wrapper varsa kaldır (Discord_Original varsa geri yükle)
if [ -d "/Applications/Discord_Original.app" ]; then
    rm -rf "/Applications/Discord.app" 2>/dev/null || true
    mv "/Applications/Discord_Original.app" "/Applications/Discord.app"
    checkmark "Orijinal Discord geri yüklendi"
fi

# ----------------------------------------------------------------------
# SPOOFDPI SERVİS SCRIPTI
# ----------------------------------------------------------------------
echo "Proxy servisi yapılandırılıyor..."

cat > "$APP_SUPPORT_DIR/spoofdpi-service.sh" << 'EOF'
#!/bin/bash
# SplitWire - SpoofDPI Servisi

SPOOF_BIN=""
for path in "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi"; do
    if [ -x "$path" ]; then
        SPOOF_BIN="$path"
        break
    fi
done

if [ -z "$SPOOF_BIN" ]; then
    echo "spoofdpi bulunamadı" >&2
    exit 1
fi

exec "$SPOOF_BIN" --listen-addr 127.0.0.1 --listen-port 8080 --enable-doh --window-size 0
EOF
chmod +x "$APP_SUPPORT_DIR/spoofdpi-service.sh"

# ----------------------------------------------------------------------
# LAUNCHAGENT
# ----------------------------------------------------------------------
PLIST_FILE="$LAUNCH_AGENTS_DIR/net.consolaktif.discord.spoofdpi.plist"

cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>net.consolaktif.discord.spoofdpi</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_SUPPORT_DIR/spoofdpi-service.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/spoofdpi.out.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/spoofdpi.err.log</string>
</dict>
</plist>
EOF

launchctl load -w "$PLIST_FILE"
sleep 2

if pgrep -x "spoofdpi" >/dev/null; then
    checkmark "Proxy servisi çalışıyor"
else
    warning "Proxy servisi başlatılamadı, manuel kontrol gerekebilir"
fi

# ----------------------------------------------------------------------
# SPLITWIRE DISCORD UYGULAMASI OLUŞTUR
# ----------------------------------------------------------------------
echo "SplitWire Discord uygulaması oluşturuluyor..."

SPLITWIRE_APP="/Applications/SplitWire Discord.app"
rm -rf "$SPLITWIRE_APP"
mkdir -p "$SPLITWIRE_APP/Contents/MacOS"
mkdir -p "$SPLITWIRE_APP/Contents/Resources"

# Info.plist
cat > "$SPLITWIRE_APP/Contents/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SplitWire</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>net.consolaktif.splitwire.discord</string>
    <key>CFBundleName</key>
    <string>SplitWire Discord</string>
    <key>CFBundleDisplayName</key>
    <string>SplitWire Discord</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

# Başlatıcı script
cat > "$SPLITWIRE_APP/Contents/MacOS/SplitWire" << 'LAUNCHER_EOF'
#!/bin/bash
# =============================================================================
# SplitWire Discord Başlatıcı
# =============================================================================

# Discord zaten açıksa ön plana getir
if pgrep -x "Discord" > /dev/null 2>&1; then
    osascript -e 'tell application "Discord" to activate'
    exit 0
fi

# spoofdpi kontrolü
PROXY_READY=false

if nc -z 127.0.0.1 8080 2>/dev/null; then
    PROXY_READY=true
else
    # Servisi başlatmayı dene
    launchctl kickstart gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
    
    # Bekle
    for i in 1 2 3 4 5; do
        sleep 1
        if nc -z 127.0.0.1 8080 2>/dev/null; then
            PROXY_READY=true
            break
        fi
    done
fi

# Discord'u başlat
DISCORD_APP="/Applications/Discord.app"

if [ "$PROXY_READY" = true ]; then
    # Proxy hazır - proxy ile başlat
    export http_proxy="http://127.0.0.1:8080"
    export https_proxy="http://127.0.0.1:8080"
    "$DISCORD_APP/Contents/MacOS/Discord" --proxy-server="http://127.0.0.1:8080" &
else
    # Proxy hazır değil - uyar ve normal başlat
    osascript -e 'display notification "Proxy hazır değil, normal başlatılıyor" with title "SplitWire"'
    open -a Discord
fi
LAUNCHER_EOF

chmod +x "$SPLITWIRE_APP/Contents/MacOS/SplitWire"

# İkonu Discord'dan kopyala
DISCORD_ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
if [ -f "$DISCORD_ICON" ]; then
    cp "$DISCORD_ICON" "$SPLITWIRE_APP/Contents/Resources/AppIcon.icns"
fi

# Quarantine temizle
xattr -cr "$SPLITWIRE_APP" 2>/dev/null || true

checkmark "SplitWire Discord uygulaması oluşturuldu"

# ----------------------------------------------------------------------
# KONTROL ARACI
# ----------------------------------------------------------------------
cat > "$APP_SUPPORT_DIR/control.sh" << 'CTRL_EOF'
#!/bin/bash
case "${1:-}" in
    start)
        launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist 2>/dev/null
        launchctl kickstart gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null
        echo "Servis başlatıldı"
        ;;
    stop)
        launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null
        pkill -x spoofdpi 2>/dev/null
        echo "Servis durduruldu"
        ;;
    status)
        if pgrep -x "spoofdpi" >/dev/null; then
            echo "Aktif"
        else
            echo "Pasif"
        fi
        ;;
    *)
        echo "Kullanım: $0 {start|stop|status}"
        ;;
esac
CTRL_EOF
chmod +x "$APP_SUPPORT_DIR/control.sh"

# ----------------------------------------------------------------------
# TAMAMLANDI
# ----------------------------------------------------------------------
echo
hr
echo "${GRN}✅ KURULUM TAMAMLANDI!${RST}"
hr
echo
echo "📋 ${YLW}KULLANIM:${RST}"
echo
echo "   ${GRN}Discord'u proxy ile açmak için:${RST}"
echo "   → /Applications/SplitWire Discord.app"
echo "   → Spotlight'ta \"SplitWire\" yazarak"
echo "   → Dock'a sürükleyerek"
echo
echo "   ${YLW}Normal Discord için:${RST}"
echo "   → /Applications/Discord.app (her zamanki gibi)"
echo
echo "📂 ${YLW}DOSYA YAPISI:${RST}"
echo "   • Discord.app          → Orijinal (dokunulmadı)"
echo "   • SplitWire Discord.app → Proxy ile başlatır"
echo
echo "🔧 ${YLW}PROXY SERVİSİ:${RST}"
echo "   • Otomatik başlıyor (LaunchAgent)"
echo "   • Kontrol: ~/Library/Application Support/Consolaktif-Discord/control.sh"
echo