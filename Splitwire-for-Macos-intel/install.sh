#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti - Minimal Müdahale (Intel)
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
title() { hr; echo "${GRN}SplitWire • Minimal Kurulum (Intel)${RST}"; hr; }

title

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOMEBREW_PATH="/usr/local"

# M-serisi uyarısı
if [ "$(uname -m)" = "arm64" ]; then
    warning "Bu Mac Apple Silicon görünüyor. M-serisi klasörünü kullanmanız önerilir."
    read -p "Devam? (e/H): " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Ee]$ ]] && exit 1
fi

# Klasörler
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"
mkdir -p "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# Bağımlılıklar
echo "Bağımlılıklar kontrol ediliyor..."

if ! command -v brew >/dev/null 2>&1; then
    if [ -x "$HOMEBREW_PATH/bin/brew" ]; then
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
    elif [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        error "Homebrew bulunamadı!"
        exit 1
    fi
fi

if ! brew list spoofdpi &>/dev/null; then
    warning "spoofdpi kuruluyor..."
    brew install spoofdpi
fi
checkmark "spoofdpi hazır"

DISCORD_APP="/Applications/Discord.app"
DISCORD_PLIST="$DISCORD_APP/Contents/Info.plist"

if [ ! -d "$DISCORD_APP" ]; then
    error "Discord.app bulunamadı!"
    exit 1
fi
checkmark "Discord.app mevcut"

# Eski kurulumları temizle
echo "Eski kurulumlar temizleniyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true

if [ -d "/Applications/Discord_Original.app" ]; then
    rm -rf "$DISCORD_APP"
    mv "/Applications/Discord_Original.app" "$DISCORD_APP"
fi
rm -rf "/Applications/SplitWire Discord.app" 2>/dev/null || true

# spoofdpi servisi
echo "Proxy servisi yapılandırılıyor..."

cat > "$APP_SUPPORT_DIR/spoofdpi-service.sh" << 'EOF'
#!/bin/bash
for path in "/usr/local/bin/spoofdpi" "/opt/homebrew/bin/spoofdpi"; do
    if [ -x "$path" ]; then
        exec "$path" --listen-addr 127.0.0.1 --listen-port 8080 --enable-doh --window-size 0
    fi
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

# Discord LSEnvironment
echo "Discord yapılandırılıyor..."
echo "${YLW}Şifreniz istenecek (Discord dosyalarını değiştirmek için):${RST}"
sudo -v

BACKUP_PLIST="$APP_SUPPORT_DIR/Info.plist.backup"
if [ ! -f "$BACKUP_PLIST" ]; then
    sudo cp "$DISCORD_PLIST" "$BACKUP_PLIST"
    sudo chown $(whoami) "$BACKUP_PLIST"
fi

TEMP_PLIST="/tmp/discord_info_plist_temp.plist"

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

with open("$TEMP_PLIST", 'wb') as f:
    plistlib.dump(plist, f)
PYEOF

sudo cp "$TEMP_PLIST" "$DISCORD_PLIST"
rm -f "$TEMP_PLIST"

sudo codesign --force --deep --sign - "$DISCORD_APP" 2>/dev/null || sudo xattr -cr "$DISCORD_APP"
sudo xattr -dr com.apple.quarantine "$DISCORD_APP" 2>/dev/null || true

checkmark "Discord yapılandırıldı"

# Kontrol scripti
cat > "$APP_SUPPORT_DIR/control.sh" << 'CTRL_EOF'
#!/bin/bash
case "${1:-}" in
    start) launchctl load -w ~/Library/LaunchAgents/net.consolaktif.discord.spoofdpi.plist 2>/dev/null; echo "Başlatıldı" ;;
    stop) launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null; pkill -x spoofdpi 2>/dev/null; echo "Durduruldu" ;;
    status) pgrep -x "spoofdpi" >/dev/null && echo "Aktif" || echo "Pasif" ;;
    restore)
        B="$HOME/Library/Application Support/Consolaktif-Discord/Info.plist.backup"
        [ -f "$B" ] && cp "$B" /Applications/Discord.app/Contents/Info.plist && codesign --force --deep --sign - /Applications/Discord.app 2>/dev/null && echo "Geri yüklendi"
        ;;
    *) echo "Kullanım: $0 {start|stop|status|restore}" ;;
esac
CTRL_EOF
chmod +x "$APP_SUPPORT_DIR/control.sh"

echo
hr
echo "${GRN}✅ KURULUM TAMAMLANDI!${RST}"
hr
echo
echo "🚀 Discord'u her zamanki gibi açın - otomatik proxy kullanacak!"
echo