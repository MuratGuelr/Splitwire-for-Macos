#!/usr/bin/env bash
# =============================================================================
# SplitWire Kurulum Scripti - macOS 26 Uyumlu
# =============================================================================
# Discord'u ~/Applications'a taşıyarak SIP kısıtlamasını atlar.
# Nereden açarsan aç proxy ile çalışır!
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
USER_APPS="$HOME/Applications"
APP_SUPPORT_DIR="$HOME/Library/Application Support/Consolaktif-Discord"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOG_DIR="$HOME/Library/Logs/ConsolAktifSplitWireLog"

mkdir -p "$USER_APPS" "$APP_SUPPORT_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"

# ----------------------------------------------------------------------
# BAĞIMLILIKLAR
# ----------------------------------------------------------------------
echo "Bağımlılıklar kontrol ediliyor..."

if ! command -v brew >/dev/null 2>&1; then
    if [ -x "$HOMEBREW_PATH/bin/brew" ]; then
        eval "$($HOMEBREW_PATH/bin/brew shellenv)"
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

# ----------------------------------------------------------------------
# DISCORD KONTROLÜ VE TAŞIMA
# ----------------------------------------------------------------------
SYSTEM_DISCORD="/Applications/Discord.app"
USER_DISCORD="$USER_APPS/Discord.app"
DISCORD_PLIST="$USER_DISCORD/Contents/Info.plist"

echo "Discord kontrol ediliyor..."

# Eğer system Discord varsa ve user Discord yoksa, kopyala
if [ -d "$SYSTEM_DISCORD" ] && [ ! -d "$USER_DISCORD" ]; then
    echo "  -> Discord ~/Applications'a kopyalanıyor..."
    cp -R "$SYSTEM_DISCORD" "$USER_DISCORD"
    checkmark "Discord ~/Applications'a kopyalandı"
elif [ -d "$USER_DISCORD" ]; then
    checkmark "Discord ~/Applications'da mevcut"
elif [ ! -d "$SYSTEM_DISCORD" ] && [ ! -d "$USER_DISCORD" ]; then
    error "Discord bulunamadı! Önce Discord'u kurun."
    exit 1
fi

# Quarantine kaldır
xattr -cr "$USER_DISCORD" 2>/dev/null || true

# ----------------------------------------------------------------------
# ESKİ KURULUMLARI TEMİZLE
# ----------------------------------------------------------------------
echo "Eski kurulumlar temizleniyor..."
launchctl bootout gui/$(id -u)/net.consolaktif.discord.spoofdpi 2>/dev/null || true
pkill -x spoofdpi 2>/dev/null || true
pkill -x Discord 2>/dev/null || true

# ----------------------------------------------------------------------
# SPOOFDPI SERVİSİ
# ----------------------------------------------------------------------
echo "Proxy servisi yapılandırılıyor..."

cat > "$APP_SUPPORT_DIR/spoofdpi-service.sh" << 'EOF'
#!/bin/bash
for path in "/opt/homebrew/bin/spoofdpi" "/usr/local/bin/spoofdpi"; do
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

if pgrep -x "spoofdpi" >/dev/null; then
    checkmark "Proxy servisi çalışıyor"
else
    warning "Proxy servisi başlatılamadı"
fi

# ----------------------------------------------------------------------
# DISCORD YAPILANDIRMASI (LSEnvironment)
# ----------------------------------------------------------------------
echo "Discord yapılandırılıyor..."

# Orijinal plist'i yedekle
BACKUP_PLIST="$APP_SUPPORT_DIR/Info.plist.backup"
if [ ! -f "$BACKUP_PLIST" ]; then
    cp "$DISCORD_PLIST" "$BACKUP_PLIST"
    checkmark "Orijinal Info.plist yedeklendi"
fi

# LSEnvironment ekle
echo "  -> LSEnvironment ekleniyor..."

python3 << PYEOF
import plistlib

plist_path = "$DISCORD_PLIST"

with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

plist['LSEnvironment'] = {
    'http_proxy': 'http://127.0.0.1:8080',
    'https_proxy': 'http://127.0.0.1:8080',
    'HTTP_PROXY': 'http://127.0.0.1:8080',
    'HTTPS_PROXY': 'http://127.0.0.1:8080',
    'all_proxy': 'http://127.0.0.1:8080',
    'ALL_PROXY': 'http://127.0.0.1:8080'
}

with open(plist_path, 'wb') as f:
    plistlib.dump(plist, f)
PYEOF

echo "  -> LSEnvironment eklendi"

# İmzala
echo "  -> Uygulama imzalanıyor..."
codesign --force --deep --sign - "$USER_DISCORD" 2>/dev/null || true

# Quarantine kaldır
xattr -cr "$USER_DISCORD" 2>/dev/null || true

# LaunchServices cache temizle ve yeni konumu kaydet
echo "  -> LaunchServices güncelleniyor..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$USER_DISCORD" 2>/dev/null || true

checkmark "Discord yapılandırıldı"

# ----------------------------------------------------------------------
# DOCK İKONU (Opsiyonel)
# ----------------------------------------------------------------------
echo
echo "${YLW}ÖNEMLİ: Discord'u Dock'tan kaldırıp ~/Applications'daki yeni Discord'u ekleyin!${RST}"
echo
echo "Yapılması gerekenler:"
echo "  1. Dock'taki eski Discord ikonuna sağ tık → 'Seçenekler' → 'Dock'tan Kaldır'"
echo "  2. Finder'da Git → Ana Klasör → Applications → Discord'u Dock'a sürükle"
echo
echo "Ya da Spotlight'ta 'Discord' yazıp ~/Applications olanı seçin."
echo

# Kontrol scripti
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
        if pgrep -x "spoofdpi" >/dev/null; then echo "Aktif"; else echo "Pasif"; fi
        ;;
    restore)
        BACKUP="$HOME/Library/Application Support/Consolaktif-Discord/Info.plist.backup"
        PLIST="$HOME/Applications/Discord.app/Contents/Info.plist"
        if [ -f "$BACKUP" ]; then
            cp "$BACKUP" "$PLIST"
            codesign --force --deep --sign - "$HOME/Applications/Discord.app" 2>/dev/null
            echo "Discord orijinal haline getirildi"
        fi
        ;;
    *) echo "Kullanım: $0 {start|stop|status|restore}" ;;
esac
CTRL_EOF
chmod +x "$APP_SUPPORT_DIR/control.sh"

# ----------------------------------------------------------------------
# TAMAMLANDI
# ----------------------------------------------------------------------
hr
echo "${GRN}✅ KURULUM TAMAMLANDI!${RST}"
hr
echo
echo "📂 ${YLW}DISCORD KONUMU:${RST}"
echo "   ~/Applications/Discord.app (proxy ile çalışır)"
echo
echo "🚀 ${YLW}AÇMA YÖNTEMLERİ:${RST}"
echo "   • Finder → Ana Klasör → Applications → Discord"
echo "   • Spotlight: 'Discord' yazın (~/Applications olanı seçin)"
echo "   • Dock'a sürükleyin"
echo
echo "⚠️  ${YLW}NOT:${RST}"
echo "   /Applications/Discord.app hala duruyorsa silebilirsiniz."
echo "   Sadece ~/Applications/Discord.app kullanın."
echo