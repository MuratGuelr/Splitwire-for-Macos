#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum (Intel)
# =============================================================================
set -euo pipefail

GRN=$'\e[32m'; YLW=$'\e[33m'; RED=$'\e[31m'; RST=$'\e[0m'
ok() { echo "${GRN}✓${RST} $*"; }
warn() { echo "${YLW}!${RST} $*"; }
err() { echo "${RED}✗${RST} $*"; }
line() { echo "${YLW}────────────────────────────────────────────────────────${RST}"; }

echo; line; echo "${GRN}SplitWire Kurulumu (Intel)${RST}"; line; echo

# M-serisi uyarısı
[ "$(uname -m)" = "arm64" ] && warn "Bu Mac Apple Silicon. M-serisi klasörünü kullanın." && exit 1

SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/SplitWire"
PLIST_NAME="net.consolaktif.spoofdpi"

mkdir -p "$SUPPORT_DIR" "$AGENTS_DIR" "$LOG_DIR"

# Bağımlılıklar
echo "Bağımlılıklar..."
for bp in /usr/local/bin/brew /opt/homebrew/bin/brew; do
    [ -x "$bp" ] && eval "$($bp shellenv)" && break
done
command -v brew &>/dev/null || { err "Homebrew yok!"; exit 1; }
ok "Homebrew"

command -v spoofdpi &>/dev/null || brew install spoofdpi
ok "spoofdpi"

[ -d "/Applications/Discord.app" ] || { err "Discord yok!"; exit 1; }
ok "Discord"
echo

# Temizlik
launchctl bootout gui/$(id -u)/$PLIST_NAME 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

# Servis
echo "Proxy servisi..."
cat > "$SUPPORT_DIR/spoofdpi.sh" << 'S'
#!/bin/bash
for p in /usr/local/bin/spoofdpi /opt/homebrew/bin/spoofdpi; do
    [ -x "$p" ] && exec "$p" -addr 127.0.0.1 -port 8080 -dns-addr 1.1.1.1 -window-size 0
done
sleep 60; exit 1
S
chmod +x "$SUPPORT_DIR/spoofdpi.sh"

cat > "$AGENTS_DIR/$PLIST_NAME.plist" << P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$PLIST_NAME</string>
    <key>ProgramArguments</key><array><string>$SUPPORT_DIR/spoofdpi.sh</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>ThrottleInterval</key><integer>5</integer>
    <key>StandardOutPath</key><string>$LOG_DIR/spoofdpi.log</string>
    <key>StandardErrorPath</key><string>$LOG_DIR/spoofdpi.log</string>
</dict>
</plist>
P

launchctl load -w "$AGENTS_DIR/$PLIST_NAME.plist" 2>/dev/null || true
sleep 2
pgrep -x spoofdpi &>/dev/null && ok "Proxy çalışıyor" || warn "Proxy başlatılamadı"
echo

# Uygulama
echo "SplitWire Discord..."
APP="/Applications/SplitWire Discord.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" << 'I'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>launcher</string>
    <key>CFBundleIconFile</key><string>icon</string>
    <key>CFBundleIdentifier</key><string>net.consolaktif.splitwire</string>
    <key>CFBundleName</key><string>SplitWire Discord</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleVersion</key><string>2.0</string>
</dict>
</plist>
I

cat > "$APP/Contents/MacOS/launcher" << 'L'
#!/bin/bash
pgrep -x Discord &>/dev/null && { osascript -e 'tell application "Discord" to activate'; exit 0; }
PROXY_OK=false
nc -z 127.0.0.1 8080 2>/dev/null && PROXY_OK=true || {
    launchctl kickstart gui/$(id -u)/net.consolaktif.spoofdpi 2>/dev/null
    for i in 1 2 3 4 5; do sleep 1; nc -z 127.0.0.1 8080 && PROXY_OK=true && break; done
}
if [ "$PROXY_OK" = true ]; then
    export http_proxy="http://127.0.0.1:8080" https_proxy="http://127.0.0.1:8080" all_proxy="http://127.0.0.1:8080"
    /Applications/Discord.app/Contents/MacOS/Discord --proxy-server="http://127.0.0.1:8080" &
else
    open -a Discord
fi
L
chmod +x "$APP/Contents/MacOS/launcher"

[ -f "/Applications/Discord.app/Contents/Resources/electron.icns" ] && cp "/Applications/Discord.app/Contents/Resources/electron.icns" "$APP/Contents/Resources/icon.icns"
xattr -cr "$APP" 2>/dev/null || true

ok "SplitWire Discord oluşturuldu"
echo

line
echo "${GRN}✅ KURULUM TAMAMLANDI${RST}"
line
echo "Spotlight'ta 'SplitWire' yazın veya Dock'a ekleyin."
echo