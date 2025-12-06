#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti
# =============================================================================
# Discord'a HİÇ DOKUNMAZ. Ayrı bir "SplitWire Discord" uygulaması oluşturur.
# Bu uygulama Discord'u proxy ile başlatır.
# =============================================================================
set -euo pipefail

# Renkler
GRN=$'\e[32m'; YLW=$'\e[33m'; RED=$'\e[31m'; RST=$'\e[0m'

ok() { echo "${GRN}✓${RST} $*"; }
warn() { echo "${YLW}!${RST} $*"; }
err() { echo "${RED}✗${RST} $*"; }
line() { echo "${YLW}────────────────────────────────────────────────────────${RST}"; }

echo
line
echo "${GRN}SplitWire Kurulumu${RST}"
line
echo

# Mimari
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    BREW_PATH="/opt/homebrew"
else
    BREW_PATH="/usr/local"
fi

# Klasörler
SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/SplitWire"
PLIST_NAME="net.consolaktif.spoofdpi"

mkdir -p "$SUPPORT_DIR" "$AGENTS_DIR" "$LOG_DIR"

# =============================================================================
# 1. BAĞIMLILIKLAR
# =============================================================================
echo "Bağımlılıklar kontrol ediliyor..."

# Homebrew
if ! command -v brew &>/dev/null; then
    if [ -x "$BREW_PATH/bin/brew" ]; then
        eval "$("$BREW_PATH/bin/brew" shellenv)"
    else
        err "Homebrew bulunamadı!"
        exit 1
    fi
fi
ok "Homebrew"

# spoofdpi
if ! command -v spoofdpi &>/dev/null; then
    warn "spoofdpi kuruluyor..."
    brew install spoofdpi
fi
ok "spoofdpi"

# Discord
if [ ! -d "/Applications/Discord.app" ]; then
    err "Discord.app bulunamadı! Önce Discord'u kurun."
    exit 1
fi
ok "Discord.app"

echo

# =============================================================================
# 2. ESKİ KURULUMLARI TEMİZLE
# =============================================================================
echo "Eski kurulumlar temizleniyor..."
launchctl bootout gui/$(id -u)/$PLIST_NAME 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
sleep 1
ok "Temizlendi"
echo

# =============================================================================
# 3. SPOOFDPI SERVİSİ
# =============================================================================
echo "Proxy servisi kuruluyor..."

# Servis scripti
cat > "$SUPPORT_DIR/spoofdpi.sh" << 'SCRIPT'
#!/bin/bash
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    [ -x "$p" ] && exec "$p" -addr 127.0.0.1 -port 8080 -dns-addr 1.1.1.1 -window-size 0
done
echo "spoofdpi bulunamadı" >&2
sleep 60
exit 1
SCRIPT
chmod +x "$SUPPORT_DIR/spoofdpi.sh"

# LaunchAgent
cat > "$AGENTS_DIR/$PLIST_NAME.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$PLIST_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SUPPORT_DIR/spoofdpi.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ThrottleInterval</key>
    <integer>5</integer>
    <key>StandardOutPath</key>
    <string>$LOG_DIR/spoofdpi.log</string>
    <key>StandardErrorPath</key>
    <string>$LOG_DIR/spoofdpi.log</string>
</dict>
</plist>
PLIST

# Servisi başlat
launchctl load -w "$AGENTS_DIR/$PLIST_NAME.plist" 2>/dev/null || true
sleep 2

if pgrep -x spoofdpi &>/dev/null; then
    ok "Proxy servisi çalışıyor"
else
    warn "Proxy servisi başlatılamadı (manuel başlatma gerekebilir)"
fi
echo

# =============================================================================
# 4. SPLITWIRE DISCORD UYGULAMASI
# =============================================================================
echo "SplitWire Discord uygulaması oluşturuluyor..."

APP="/Applications/SplitWire Discord.app"
rm -rf "$APP"

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Info.plist
cat > "$APP/Contents/Info.plist" << 'INFO'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>launcher</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>net.consolaktif.splitwire</string>
    <key>CFBundleName</key>
    <string>SplitWire Discord</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>2.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
INFO

# Launcher script
cat > "$APP/Contents/MacOS/launcher" << 'LAUNCHER'
#!/bin/bash

# Discord zaten açıksa ön plana getir
if pgrep -x Discord &>/dev/null; then
    osascript -e 'tell application "Discord" to activate' 2>/dev/null
    exit 0
fi

# Proxy kontrol
PROXY_OK=false
if nc -z 127.0.0.1 8080 2>/dev/null; then
    PROXY_OK=true
else
    # Servisi başlatmayı dene
    launchctl kickstart gui/$(id -u)/net.consolaktif.spoofdpi 2>/dev/null || true
    for i in 1 2 3 4 5; do
        sleep 1
        nc -z 127.0.0.1 8080 2>/dev/null && PROXY_OK=true && break
    done
fi

# Discord'u başlat
if [ "$PROXY_OK" = true ]; then
    # Proxy ile başlat
    export http_proxy="http://127.0.0.1:8080"
    export https_proxy="http://127.0.0.1:8080"
    export all_proxy="http://127.0.0.1:8080"
    /Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:8080" &
else
    # Proxy yok, normal başlat
    osascript -e 'display notification "Proxy hazır değil" with title "SplitWire"' 2>/dev/null
    open -a Discord
fi
LAUNCHER
chmod +x "$APP/Contents/MacOS/launcher"

# İkon kopyala
ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
[ -f "$ICON" ] && cp "$ICON" "$APP/Contents/Resources/icon.icns"

# Quarantine kaldır
xattr -cr "$APP" 2>/dev/null || true

ok "SplitWire Discord.app oluşturuldu"
echo

# =============================================================================
# 5. KONTROL ARACI
# =============================================================================
cat > "$SUPPORT_DIR/control.sh" << 'CTRL'
#!/bin/bash
case "$1" in
    start)
        launchctl load -w ~/Library/LaunchAgents/net.consolaktif.spoofdpi.plist
        launchctl kickstart gui/$(id -u)/net.consolaktif.spoofdpi
        echo "Başlatıldı"
        ;;
    stop)
        launchctl bootout gui/$(id -u)/net.consolaktif.spoofdpi 2>/dev/null
        pkill -x spoofdpi
        echo "Durduruldu"
        ;;
    status)
        pgrep -x spoofdpi &>/dev/null && echo "Çalışıyor" || echo "Durdu"
        ;;
    *)
        echo "Kullanım: $0 start|stop|status"
        ;;
esac
CTRL
chmod +x "$SUPPORT_DIR/control.sh"

# =============================================================================
# 6. BİTİŞ
# =============================================================================
line
echo "${GRN}✅ KURULUM TAMAMLANDI${RST}"
line
echo
echo "📌 ${YLW}KULLANIM:${RST}"
echo "   1. Spotlight'ta 'SplitWire' yazın"
echo "   2. Ya da: /Applications/SplitWire Discord.app"
echo "   3. Dock'a sürükleyip sabitleyin"
echo
echo "📝 ${YLW}NOT:${RST}"
echo "   • Discord.app'a dokunulmadı, orijinal haliyle duruyor"
echo "   • SplitWire Discord'u açınca proxy ile çalışır"
echo "   • spoofdpi arka planda sürekli çalışıyor"
echo
echo "🔧 ${YLW}KONTROL:${RST}"
echo "   ~/Library/Application Support/Consolaktif-Discord/control.sh start|stop|status"
echo