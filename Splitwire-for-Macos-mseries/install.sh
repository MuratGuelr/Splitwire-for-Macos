#!/usr/bin/env bash
# =============================================================================
# SplitWire - macOS için DPI Bypass
# =============================================================================
# Basit, güvenilir, kesinlikle çalışan versiyon
# =============================================================================
set -e

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  SplitWire Kurulumu"
echo "═══════════════════════════════════════════════════════"
echo ""

# ------------------------------------------------------------------------------
# 1. HOMEBREW KONTROLÜ
# ------------------------------------------------------------------------------
echo "[1/4] Homebrew kontrol ediliyor..."

BREW=""
if [ -x "/opt/homebrew/bin/brew" ]; then
    BREW="/opt/homebrew/bin/brew"
elif [ -x "/usr/local/bin/brew" ]; then
    BREW="/usr/local/bin/brew"
fi

if [ -z "$BREW" ]; then
    echo "HATA: Homebrew bulunamadı!"
    echo "Kurulum: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

eval "$($BREW shellenv)"
echo "  ✓ Homebrew: $BREW"

# ------------------------------------------------------------------------------
# 2. SPOOFDPI KURULUMU
# ------------------------------------------------------------------------------
echo ""
echo "[2/4] spoofdpi kontrol ediliyor..."

SPOOFDPI=$(command -v spoofdpi 2>/dev/null || true)

if [ -z "$SPOOFDPI" ]; then
    echo "  → spoofdpi kuruluyor..."
    $BREW install spoofdpi
    SPOOFDPI=$(command -v spoofdpi)
fi

echo "  ✓ spoofdpi: $SPOOFDPI"

# Test et
echo "  → spoofdpi test ediliyor..."
$SPOOFDPI --version 2>/dev/null || $SPOOFDPI -v 2>/dev/null || echo "  (versiyon bilgisi alınamadı)"

# ------------------------------------------------------------------------------
# 3. DISCORD KONTROLÜ
# ------------------------------------------------------------------------------
echo ""
echo "[3/4] Discord kontrol ediliyor..."

if [ ! -d "/Applications/Discord.app" ]; then
    echo "HATA: Discord.app bulunamadı!"
    echo "Önce Discord'u kurun: https://discord.com/download"
    exit 1
fi

echo "  ✓ Discord.app mevcut"

# Discord'u kapat (proxy ayarlarını almak için)
pkill -x Discord 2>/dev/null || true

# ------------------------------------------------------------------------------
# 4. DOSYALARI OLUŞTUR
# ------------------------------------------------------------------------------
echo ""
echo "[4/4] Dosyalar oluşturuluyor..."

SUPPORT="$HOME/Library/Application Support/SplitWire"
AGENTS="$HOME/Library/LaunchAgents"
LOGS="$HOME/Library/Logs/SplitWire"

mkdir -p "$SUPPORT" "$AGENTS" "$LOGS"

# Eski servisi durdur
launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
sleep 1

# --- spoofdpi başlatma scripti ---
cat > "$SUPPORT/start-spoofdpi.sh" << 'SCRIPT'
#!/bin/bash
# spoofdpi'yi bul ve başlat
for p in /opt/homebrew/bin/spoofdpi /usr/local/bin/spoofdpi; do
    if [ -x "$p" ]; then
        exec "$p" 2>&1
    fi
done
echo "spoofdpi bulunamadı"
exit 1
SCRIPT
chmod +x "$SUPPORT/start-spoofdpi.sh"

# --- LaunchAgent ---
cat > "$AGENTS/com.splitwire.spoofdpi.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.splitwire.spoofdpi</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SUPPORT/start-spoofdpi.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$LOGS/spoofdpi.log</string>
    <key>StandardErrorPath</key>
    <string>$LOGS/spoofdpi.log</string>
</dict>
</plist>
PLIST

# Servisi başlat
launchctl load -w "$AGENTS/com.splitwire.spoofdpi.plist"
sleep 3

# Kontrol
if pgrep -x spoofdpi > /dev/null; then
    echo "  ✓ spoofdpi servisi çalışıyor"
else
    echo "  ! spoofdpi başlatılamadı, log kontrol edin: $LOGS/spoofdpi.log"
fi

# Port kontrolü
if nc -z 127.0.0.1 8080 2>/dev/null; then
    echo "  ✓ Port 8080 açık"
else
    echo "  ! Port 8080 kapalı - spoofdpi farklı port kullanıyor olabilir"
    # Log'dan portu bul
    sleep 2
    PORT=$(grep -o "listening on.*:[0-9]*" "$LOGS/spoofdpi.log" 2>/dev/null | grep -o "[0-9]*$" | tail -1)
    if [ -n "$PORT" ]; then
        echo "  → spoofdpi port: $PORT"
    fi
fi

# --- SplitWire Discord.app ---
APP="/Applications/SplitWire Discord.app"
rm -rf "$APP"

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" << 'INFO'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>run</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>com.splitwire.discord</string>
    <key>CFBundleName</key>
    <string>SplitWire Discord</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>2.1</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
INFO

# Launcher - log'dan portu oku veya 8080 kullan
cat > "$APP/Contents/MacOS/run" << 'LAUNCHER'
#!/bin/bash

LOG_FILE="$HOME/Library/Logs/SplitWire/spoofdpi.log"

# Port bul - log'dan veya varsayılan
PORT=8080
if [ -f "$LOG_FILE" ]; then
    FOUND_PORT=$(grep -o "listening on.*:[0-9]*" "$LOG_FILE" 2>/dev/null | grep -o "[0-9]*$" | tail -1)
    [ -n "$FOUND_PORT" ] && PORT=$FOUND_PORT
fi

# Discord zaten açıksa ön plana getir
if pgrep -x Discord > /dev/null; then
    osascript -e 'tell application "Discord" to activate' 2>/dev/null
    exit 0
fi

# spoofdpi çalışıyor mu?
if ! pgrep -x spoofdpi > /dev/null; then
    launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null
    sleep 3
fi

# Port açık mı kontrol et
PROXY_OK=false
for i in 1 2 3 4 5; do
    if nc -z 127.0.0.1 $PORT 2>/dev/null; then
        PROXY_OK=true
        break
    fi
    sleep 1
done

# Discord'u başlat
if [ "$PROXY_OK" = true ]; then
    export http_proxy="http://127.0.0.1:$PORT"
    export https_proxy="http://127.0.0.1:$PORT"
    export all_proxy="http://127.0.0.1:$PORT"
    /Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:$PORT" &
else
    osascript -e 'display notification "Proxy başlatılamadı, normal açılıyor" with title "SplitWire"' 2>/dev/null
    open -a Discord
fi
LAUNCHER
chmod +x "$APP/Contents/MacOS/run"

# İkon
ICON="/Applications/Discord.app/Contents/Resources/electron.icns"
[ -f "$ICON" ] && cp "$ICON" "$APP/Contents/Resources/icon.icns"

# Quarantine kaldır
xattr -cr "$APP" 2>/dev/null || true

echo "  ✓ SplitWire Discord.app oluşturuldu"

# ------------------------------------------------------------------------------
# BİTİŞ
# ------------------------------------------------------------------------------
echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ KURULUM TAMAMLANDI"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  KULLANIM:"
echo "  ─────────"
echo "  1. Spotlight'ta 'SplitWire' yazın"
echo "  2. Ya da Finder'da: /Applications/SplitWire Discord.app"
echo "  3. Dock'a sürükleyip sabitleyin"
echo ""
echo "  KONTROL:"
echo "  ────────"
echo "  • spoofdpi durumu: pgrep -x spoofdpi && echo 'Çalışıyor'"
echo "  • Loglar: cat ~/Library/Logs/SplitWire/spoofdpi.log"
echo "  • Servisi yeniden başlat: launchctl kickstart -k gui/\$(id -u)/com.splitwire.spoofdpi"
echo ""
echo "  KALDIRMA:"
echo "  ─────────"
echo "  ./uninstall.sh"
echo ""