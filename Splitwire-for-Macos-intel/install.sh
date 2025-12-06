#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti - macOS 26 Uyumlu (Intel)
# =============================================================================
set -euo pipefail

GRN=$(tput setaf 2 2>/dev/null || echo "")
YLW=$(tput setaf 3 2>/dev/null || echo "")
RED=$(tput setaf 1 2>/dev/null || echo "")
RST=$(tput sgr0 2>/dev/null || echo "")

checkmark() { echo "${GRN}✔${RST} $*"; }
warning() { echo "${YLW}⚠${RST} $*"; }
error() { echo "${RED}✖${RST} $*"; }
hr() { printf "\n${YLW}────────────────────────────────────────────────────────${RST}\n"; }

hr; echo "${GRN}SplitWire • Kurulum (Intel)${RST}"; hr

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# M-serisi uyarısı
if [ "$(uname -m)" = "arm64" ]; then
    warning "Bu Mac Apple Silicon. M-serisi klasörünü kullanmanız önerilir."
    read -p "Devam? (e/H): " -n 1 -r; echo
    [[ ! $REPLY =~ ^[Ee]$ ]] && exit 1
fi

# Klasörler
USER_APPS="$HOME/Applications"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$USER_APPS" "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# Homebrew
echo "Bağımlılıklar kontrol ediliyor..."
if ! command -v brew >/dev/null 2>&1; then
    for bp in "/usr/local/bin/brew" "/opt/homebrew/bin/brew"; do
        [ -x "$bp" ] && eval "$($bp shellenv)" && break
    done
fi

if ! brew list spoofdpi &>/dev/null; then
    warning "spoofdpi kuruluyor..."
    brew install spoofdpi
fi
checkmark "spoofdpi hazır"

# Discord
SYSTEM_DISCORD="/Applications/Discord.app"
USER_DISCORD="$USER_APPS/Discord.app"
DISCORD_PLIST="$USER_DISCORD/Contents/Info.plist"

echo "Discord kontrol ediliyor..."
if [ -d "$SYSTEM_DISCORD" ] && [ ! -d "$USER_DISCORD" ]; then
    echo "  -> Discord ~/Applications'a kopyalanıyor..."
    cp -R "$SYSTEM_DISCORD" "$USER_DISCORD"
    checkmark "Discord kopyalandı"
elif [ -d "$USER_DISCORD" ]; then
    checkmark "Discord ~/Applications'da mevcut"
else
    error "Discord bulunamadı!"
    exit 1
fi

xattr -cr "$USER_DISCORD" 2>/dev/null || true

# Temizlik
echo "Eski kurulumlar temizleniyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
pkill -x Discord 2>/dev/null || true

# spoofdpi servisi
echo "Proxy servisi yapılandırılıyor..."

cat > "$APP_SUPPORT_DIR/spoofdpi-service.sh" << 'EOF'
#!/bin/bash
for path in "/usr/local/bin/spoofdpi" "/opt/homebrew/bin/spoofdpi"; do
    [ -x "$path" ] && exec "$path" --listen-addr 127.0.0.1 --listen-port 8080 --enable-doh --window-size 0
done
exit 1
EOF
chmod +x "$APP_SUPPORT_DIR/spoofdpi-service.sh"

cat > "$LAUNCH_AGENTS_DIR/net.consolaktif.discord.spoofdpi.plist" << EOF
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

launchctl load -w "$LAUNCH_AGENTS_DIR/net.consolaktif.discord.spoofdpi.plist"
sleep 2
pgrep -x "spoofdpi" >/dev/null && checkmark "Proxy servisi çalışıyor" || warning "Proxy başlatılamadı"

# Discord yapılandırması
echo "Discord yapılandırılıyor..."

BACKUP_PLIST="$APP_SUPPORT_DIR/Info.plist.backup"
[ ! -f "$BACKUP_PLIST" ] && cp "$DISCORD_PLIST" "$BACKUP_PLIST"

python3 << PYEOF
import plistlib
with open("$DISCORD_PLIST", 'rb') as f:
    plist = plistlib.load(f)
plist['LSEnvironment'] = {
    'http_proxy': 'http://127.0.0.1:8080',
    'https_proxy': 'http://127.0.0.1:8080',
    'HTTP_PROXY': 'http://127.0.0.1:8080',
    'HTTPS_PROXY': 'http://127.0.0.1:8080',
    'all_proxy': 'http://127.0.0.1:8080',
    'ALL_PROXY': 'http://127.0.0.1:8080'
}
with open("$DISCORD_PLIST", 'wb') as f:
    plistlib.dump(plist, f)
PYEOF

codesign --force --deep --sign - "$USER_DISCORD" 2>/dev/null || true
xattr -cr "$USER_DISCORD" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$USER_DISCORD" 2>/dev/null || true

checkmark "Discord yapılandırıldı"

# Kontrol scripti
cat > "$APP_SUPPORT_DIR/control.sh" << 'CTRL_EOF'
#!/bin/bash
case "${1:-}" in
    start) launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist; echo "Başlatıldı" ;;
    stop) launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null; pkill -x spoofdpi; echo "Durduruldu" ;;
    status) pgrep -x "spoofdpi" >/dev/null && echo "Aktif" || echo "Pasif" ;;
    *) echo "Kullanım: $0 {start|stop|status}" ;;
esac
CTRL_EOF
chmod +x "$APP_SUPPORT_DIR/control.sh"

hr
echo "${GRN}✅ KURULUM TAMAMLANDI!${RST}"
hr
echo
echo "📂 Discord: ~/Applications/Discord.app"
echo "🚀 Finder → Ana Klasör → Applications → Discord'u Dock'a ekleyin"
echo