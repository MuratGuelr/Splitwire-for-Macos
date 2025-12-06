#!/usr/bin/env bash
# SplitWire - Intel macOS
set -e

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  SplitWire Kurulumu (Intel)"
echo "═══════════════════════════════════════════════════════"
echo ""

# M-serisi uyarısı
if [ "$(uname -m)" = "arm64" ]; then
    echo "UYARI: Bu Mac Apple Silicon. M-serisi klasörünü kullanın."
    exit 1
fi

# Homebrew
echo "[1/4] Homebrew..."
BREW=""
for p in /usr/local/bin/brew /opt/homebrew/bin/brew; do
    [ -x "$p" ] && BREW="$p" && break
done
[ -z "$BREW" ] && echo "HATA: Homebrew yok!" && exit 1
eval "$($BREW shellenv)"
echo "  ✓ $BREW"

# spoofdpi
echo "[2/4] spoofdpi..."
command -v spoofdpi &>/dev/null || $BREW install spoofdpi
echo "  ✓ $(command -v spoofdpi)"

# Discord
echo "[3/4] Discord..."
[ ! -d "/Applications/Discord.app" ] && echo "HATA: Discord yok!" && exit 1
echo "  ✓ Discord.app"
pkill -x Discord 2>/dev/null || true

# Dosyalar
echo "[4/4] Dosyalar..."
SUPPORT="$HOME/Library/Application Support/SplitWire"
AGENTS="$HOME/Library/LaunchAgents"
LOGS="$HOME/Library/Logs/SplitWire"
mkdir -p "$SUPPORT" "$AGENTS" "$LOGS"

launchctl bootout gui/$(id -u)/com.splitwire.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
sleep 1

cat > "$SUPPORT/start-spoofdpi.sh" << 'S'
#!/bin/bash
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && exec "$p" 2>&1
done
exit 1
S
chmod +x "$SUPPORT/start-spoofdpi.sh"

cat > "$AGENTS/com.splitwire.spoofdpi.plist" << P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.splitwire.spoofdpi</string>
    <key>ProgramArguments</key><array><string>$SUPPORT/start-spoofdpi.sh</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>$LOGS/spoofdpi.log</string>
    <key>StandardErrorPath</key><string>$LOGS/spoofdpi.log</string>
</dict>
</plist>
P

launchctl load -w "$AGENTS/com.splitwire.spoofdpi.plist"
sleep 3
pgrep -x spoofdpi > /dev/null && echo "  ✓ spoofdpi çalışıyor" || echo "  ! spoofdpi başlatılamadı"

# App
APP="/Applications/SplitWire Discord.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" << 'I'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>run</string>
    <key>CFBundleIconFile</key><string>icon</string>
    <key>CFBundleIdentifier</key><string>com.splitwire.discord</string>
    <key>CFBundleName</key><string>SplitWire Discord</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>2.1</string>
</dict>
</plist>
I

cat > "$APP/Contents/MacOS/run" << 'L'
#!/bin/bash
LOG="$HOME/Library/Logs/SplitWire/spoofdpi.log"
PORT=8080
[ -f "$LOG" ] && P=$(grep -o "listening on.*:[0-9]*" "$LOG" | grep -o "[0-9]*$" | tail -1) && [ -n "$P" ] && PORT=$P

pgrep -x Discord > /dev/null && { osascript -e 'tell application "Discord" to activate'; exit 0; }
pgrep -x spoofdpi > /dev/null || { launchctl kickstart gui/$(id -u)/com.splitwire.spoofdpi; sleep 3; }

OK=false
for i in 1 2 3 4 5; do nc -z 127.0.0.1 $PORT 2>/dev/null && OK=true && break; sleep 1; done

if [ "$OK" = true ]; then
    export http_proxy="http://127.0.0.1:$PORT" https_proxy="http://127.0.0.1:$PORT" all_proxy="http://127.0.0.1:$PORT"
    /Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:$PORT" &
else
    open -a Discord
fi
L
chmod +x "$APP/Contents/MacOS/run"

[ -f "/Applications/Discord.app/Contents/Resources/electron.icns" ] && cp "/Applications/Discord.app/Contents/Resources/electron.icns" "$APP/Contents/Resources/icon.icns"
xattr -cr "$APP" 2>/dev/null || true

echo "  ✓ SplitWire Discord.app"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ KURULUM TAMAMLANDI"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  Spotlight'ta 'SplitWire' yazın veya Dock'a ekleyin."
echo ""